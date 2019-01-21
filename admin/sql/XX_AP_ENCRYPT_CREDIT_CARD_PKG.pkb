CREATE OR REPLACE PACKAGE BODY xx_ap_encrypt_credit_card_pkg
AS
    /*+=========================================================================+
    |   Office Depot - Project R12                                              |
    |   Office Depot/Consulting Organization                                    |
    +===========================================================================+
    |Name        : xx_ap_encrypt_credit_card_pkg                                |
    |RICE        : I2168                                                        |
    |Description : This package performs custom encryption on any new credit    |
    |              card account included in JP Morgan Files inbound files.      |
    |                                                                           |
    |              Here are the steps:                                          |
    |               1. Look for credit card account in file.                    |
    |               2. For each credit card account do the below.               |
    |               3. Get or create the credit card.                           |
    |               4. Get the credit card information                          |
    |               5  Check if credit card has been previously encrypted       |
    |                  using custom encryption.                                 |
    |               6. If not previously custom encrypted, encrypt it           |
    |               7. Update the credit card record with the custom encryption |
    |                  information.                                             |
    |               8. Submit seeded program to load and valid file             |
    |Change Record:                                                             |
    |==============                                                             |
    |Version  Date         Author                  Remarks                      |
    |=======  ===========  ======================  =============================|
    |  1.0    24-OCT-2013  Edson Morales            Initial Version.            |
    |  2.0    17-DEC-2013  Edson Morales            Modified to have the master |
    |                                               program wait till the child |
    |                                               program has completed.      |
    |  3.0    29-JAN-2014  Edson Morales            Added check to make sure    |
    |                                               encryption call did not     |
    |                                               return an error and also    |
    |                                               verify that the encryped    |
    |                                               value was returned and the  |
    |                                               encryption label.           |
    |  4.0   21-FEB-2014  Jay Gupta     Defect# 28325 - Calling standard prog   |
    |                                first and then update for custom encryption|
    |  5.0   08-APR-2014  Edson Morales Defect# 29385 -- Getting credit card num|
    |                                from ap_cards_all backup table.            |
    |  6.0   27-OCT-2015  Harvinder Rakhra          Retrofit R12.2              |
    +==========================================================================*/
    gc_package_name        CONSTANT all_objects.object_name%TYPE   := 'xx_ap_encrypt_credit_card_pkg';
    gc_ret_success         CONSTANT VARCHAR2(20)                   := 'SUCCESS';
    gc_ret_no_data_found   CONSTANT VARCHAR2(20)                   := 'NO_DATA_FOUND';
    gc_ret_too_many_rows   CONSTANT VARCHAR2(20)                   := 'TOO_MANY_ROWS';
    gc_ret_api             CONSTANT VARCHAR2(20)                   := 'API';
    gc_ret_others          CONSTANT VARCHAR2(20)                   := 'OTHERS';
    gc_max_err_size        CONSTANT NUMBER                         := 2000;
    gc_max_log_size        CONSTANT NUMBER                         := 2000;
    gc_max_err_buf_size    CONSTANT NUMBER                         := 250;
    gb_debug                        BOOLEAN                        := FALSE;
    gc_credit_card_prefix  CONSTANT VARCHAR2(20)                   := 'xxxxxxxxxxxx';

    TYPE gt_input_parameters IS TABLE OF VARCHAR2(255)
        INDEX BY VARCHAR2(30);

    TYPE gt_account_number IS TABLE OF VARCHAR2(30)
        INDEX BY BINARY_INTEGER;

    /***********************************************
    *  Setter procedure for gb_debug global variable
    *  used for controlling debugging
    ***********************************************/
    PROCEDURE set_debug(
        p_debug_flag  IN  VARCHAR2)
    IS
    BEGIN
        IF (UPPER(p_debug_flag) IN('Y', 'YES', 'T', 'TRUE'))
        THEN
            gb_debug := TRUE;
        END IF;
    END set_debug;

    /*********************************************************************
    * Procedure used to log based on gb_debug value or if p_force is TRUE.
    * Will log to dbms_output if request id is not set,
    * else will log to concurrent program log file.  Will prepend
    * timestamp to each message logged.  This is useful for determining
    * elapse times.
    *********************************************************************/
    PROCEDURE logit(
        p_message  IN  VARCHAR2,
        p_force    IN  BOOLEAN DEFAULT FALSE)
    IS
        lc_message  VARCHAR2(2000) := NULL;
    BEGIN
        --if debug is on (defaults to true)
        IF (gb_debug OR p_force)
        THEN
            lc_message :=
                    SUBSTR(   TO_CHAR(SYSTIMESTAMP,
                                      'MM/DD/YYYY HH24:MI:SS.FF')
                           || ' => '
                           || p_message,
                           1,
                           gc_max_log_size);

            -- if in concurrent program, print to log file
            IF (fnd_global.conc_request_id > 0)
            THEN
                fnd_file.put_line(fnd_file.LOG,
                                  lc_message);
            -- else print to DBMS_OUTPUT
            ELSE
                DBMS_OUTPUT.put_line(lc_message);
            END IF;
        END IF;
    EXCEPTION
        WHEN OTHERS
        THEN
            NULL;
    END logit;

    /**********************************************************************
    * Helper procedure to log the sub procedure/function name that has been
    * called and logs the input parameters passed to it.
    ***********************************************************************/
    PROCEDURE entering_sub(
        p_procedure_name  IN  VARCHAR2,
        p_parameters      IN  gt_input_parameters)
    AS
        ln_counter            NUMBER        := 0;
        lc_current_parameter  VARCHAR2(255) := NULL;
    BEGIN
        IF gb_debug
        THEN
            logit(p_message      => '-----------------------------------------------');
            logit(p_message      =>    'Entering: '
                                    || p_procedure_name);
            lc_current_parameter := p_parameters.FIRST;

            IF p_parameters.COUNT > 0
            THEN
                logit(p_message      => 'Input parameters:');

                LOOP
                    EXIT WHEN lc_current_parameter IS NULL;
                    ln_counter :=   ln_counter
                                  + 1;
                    logit(p_message      =>    ln_counter
                                            || '. '
                                            || lc_current_parameter
                                            || ' => '
                                            || p_parameters(lc_current_parameter));
                    lc_current_parameter := p_parameters.NEXT(lc_current_parameter);
                END LOOP;
            END IF;
        END IF;
    EXCEPTION
        WHEN OTHERS
        THEN
            NULL;
    END entering_sub;

    /******************************************************************
    * Helper procedure to log that the main procedure/function has been
    * called. Sets the debug flag and calls entering_sub so that
    * it logs the procedure name and the input parameters passed in.
    ******************************************************************/
    PROCEDURE entering_main(
        p_procedure_name   IN  VARCHAR2,
        p_rice_identifier  IN  VARCHAR2,
        p_debug_flag       IN  VARCHAR2,
        p_parameters       IN  gt_input_parameters)
    AS
    BEGIN
        set_debug(p_debug_flag      => p_debug_flag);

        IF gb_debug
        THEN
            IF p_rice_identifier IS NOT NULL
            THEN
                logit(p_message      => '-----------------------------------------------');
                logit(p_message      => '-----------------------------------------------');
                logit(p_message      =>    'RICE ID: '
                                        || p_rice_identifier);
                logit(p_message      => '-----------------------------------------------');
                logit(p_message      => '-----------------------------------------------');
            END IF;

            entering_sub(p_procedure_name      => p_procedure_name,
                         p_parameters          => p_parameters);
        END IF;
    EXCEPTION
        WHEN OTHERS
        THEN
            NULL;
    END entering_main;

    /****************************************************************
    * Helper procedure to log the exiting of a subprocedure.
    * This is useful for debugging and for tracking how long a given
    * procedure is taking.
    ****************************************************************/
    PROCEDURE exiting_sub(
        p_procedure_name  IN  VARCHAR2,
        p_exception_flag  IN  BOOLEAN DEFAULT FALSE)
    AS
    BEGIN
        IF gb_debug
        THEN
            IF p_exception_flag
            THEN
                logit(p_message      =>    'Exiting Exception: '
                                        || p_procedure_name);
            ELSE
                logit(p_message      =>    'Exiting: '
                                        || p_procedure_name);
            END IF;

            logit(p_message      => '-----------------------------------------------');
        END IF;
    EXCEPTION
        WHEN OTHERS
        THEN
            NULL;
    END exiting_sub;

    /****************************************************************
    * Helper function to return directory path for a given directory
    * name.
    ****************************************************************/
    FUNCTION get_full_directory_path(
        p_directory_name  IN      all_directories.directory_name%TYPE,
        x_directory_path  OUT     all_directories.directory_path%TYPE,
        x_error_message   OUT     VARCHAR2)
        RETURN VARCHAR2
    IS
        lc_procedure_name  CONSTANT VARCHAR2(60)        :=    gc_package_name
                                                           || '.'
                                                           || 'get_full_directory_path';
        lt_parameters               gt_input_parameters;
    BEGIN
        lt_parameters('p_directory_name ') := p_directory_name;
        entering_sub(p_procedure_name      => lc_procedure_name,
                     p_parameters          => lt_parameters);

        SELECT    directory_path
               || '/'
        INTO   x_directory_path
        FROM   all_directories
        WHERE  directory_name = p_directory_name;

        logit(p_message      =>    '(RESULTS) x_directory_path = '
                                || x_directory_path);
        exiting_sub(p_procedure_name      => lc_procedure_name);
        RETURN gc_ret_success;
    EXCEPTION
        WHEN NO_DATA_FOUND
        THEN
            x_error_message :=
                    SUBSTR(   lc_procedure_name
                           || ' SQLCODE: '
                           || SQLCODE
                           || ' SQLERRM: '
                           || SQLERRM,
                           1,
                           gc_max_err_size);
            exiting_sub(p_procedure_name      => lc_procedure_name,
                        p_exception_flag      => TRUE);
            RETURN gc_ret_no_data_found;
        WHEN TOO_MANY_ROWS
        THEN
            x_error_message :=
                    SUBSTR(   lc_procedure_name
                           || ' SQLCODE: '
                           || SQLCODE
                           || ' SQLERRM: '
                           || SQLERRM,
                           1,
                           gc_max_err_size);
            exiting_sub(p_procedure_name      => lc_procedure_name,
                        p_exception_flag      => TRUE);
            RETURN gc_ret_too_many_rows;
        WHEN OTHERS
        THEN
            x_error_message :=
                    SUBSTR(   lc_procedure_name
                           || ' SQLCODE: '
                           || SQLCODE
                           || ' SQLERRM: '
                           || SQLERRM,
                           1,
                           gc_max_err_size);
            exiting_sub(p_procedure_name      => lc_procedure_name,
                        p_exception_flag      => TRUE);
            RETURN gc_ret_others;
    END get_full_directory_path;

    /*****************************************************************************
    * This procedure searches credit card accounts in the XML file passed in
    *
    * For example, given the following file
    *  ----------------SAMPLE FILE -----------------------
    * <?xml version="1.0" encoding="utf-8"?>
    * <CDFTransmissionFile .........................
    *    .
    *    .
    *    .
    *    <IssuerEntity ICANumber =...............>
    *       .
    *       .
    *       .
    *       <CorporateEntity CorporationNumber = "9999999" >
    *          .
    *          .
    *          .
    *          <AccountEntity AccountNumber = "xxxxxxxxxxxx1234" >
    *  .
    *  .
    *  .
    *          <AccountEntity AccountNumber = "xxxxxxxxxxxx4567" >
    *  -----------------END OF SAMPLE FILE -------------------
    *
    * We want to get the values in for AccountNumber
    *    i.e. xxxxxxxxxxxx1234, xxxxxxxxxxxx4567"
    *
    *  p_file_target_node_path
    *     - Will depict the tag hierarchy path to the target node.
    *     - In this case the target node is AccountEntity, the value
    *       would be /CDFTransmissionFile/IssuerEntity/CorporateEntity/AccountEntity
    *
    *  p_file_target_node_item_name
    *     - Contains the pattern of the item we are looking for in the
    *       target node.
    *     - In this case the pattern of the item is AccountNumber, the value
    *       would be @AccountNumber
    *******************************************************************************/
    FUNCTION get_acct_nums_from_file(
        p_directory                   IN      all_directories.directory_name%TYPE,
        p_file_name                   IN      VARCHAR2,
        p_file_target_node_path       IN      VARCHAR2,
        p_file_target_node_item_name  IN      VARCHAR2,
        x_account_numbers             OUT     gt_account_number,
        x_error_message               OUT     VARCHAR2)
        RETURN VARCHAR2
    IS
        lc_procedure_name  CONSTANT VARCHAR2(60)            :=    gc_package_name
                                                               || '.'
                                                               || 'get_acct_nums_from_file';
        lt_parameters               gt_input_parameters;
        l_data                      XMLTYPE;
        l_doc                       DBMS_XMLDOM.domdocument;
        l_node                      DBMS_XMLDOM.domnode;
        l_nodelist                  DBMS_XMLDOM.domnodelist;
        l_buf                       VARCHAR2(32000);
        lc_action                   VARCHAR2(1000);
    BEGIN
        lt_parameters('p_directory') := p_directory;
        lt_parameters('p_file_name') := p_file_name;
        lt_parameters('p_file_target_node_path') := p_file_target_node_path;
        lt_parameters('p_file_target_node_item_name') := p_file_target_node_item_name;
        entering_sub(p_procedure_name      => lc_procedure_name,
                     p_parameters          => lt_parameters);                                        ---?? Add vl_action
        lc_action := 'Running XMLTYPE(BFILENAME(p_directory, p_file_name), NLS_CHARSET_ID(AL32UTF8))';
        l_data := XMLTYPE(BFILENAME(p_directory,
                                    p_file_name),
                          NLS_CHARSET_ID('AL32UTF8'));
        lc_action := 'Running DBMS_XMLDOM.newdomdocument(xmldoc => l_data)';
        l_doc := DBMS_XMLDOM.newdomdocument(xmldoc      => l_data);
        lc_action := 'Running DBMS_XMLDOM.makenode(doc => l_doc)';
        l_node := DBMS_XMLDOM.makenode(doc      => l_doc);
        lc_action := 'Running DBMS_XSLPROCESSOR.selectnodes(n => l_node ...';
        l_nodelist := DBMS_XSLPROCESSOR.selectnodes(n            => l_node,
                                                    pattern      => p_file_target_node_path);

        FOR cur_account IN 0 ..   DBMS_XMLDOM.getlength(nl      => l_nodelist)
                                - 1
        LOOP
            lc_action :=    'Running DBMS_XMLDOM.item(nl => l_nodelist ... for index '
                         || cur_account;
            l_node := DBMS_XMLDOM.item(nl       => l_nodelist,
                                       idx      => cur_account);
            lc_action :=    'Running DBMS_XSLPROCESSOR.valueof(n => l_node ... for index '
                         || cur_account;
            DBMS_XSLPROCESSOR.valueof(n            => l_node,
                                      pattern      => p_file_target_node_item_name,
                                      val          => x_account_numbers(  x_account_numbers.COUNT
                                                                        + 1));
        END LOOP;

        exiting_sub(p_procedure_name      => lc_procedure_name);
        RETURN gc_ret_success;
    EXCEPTION
        WHEN OTHERS
        THEN
            x_error_message :=
                SUBSTR(   lc_procedure_name
                       || ' Action: '
                       || lc_action
                       || ' SQLCODE: '
                       || SQLCODE
                       || ' SQLERRM: '
                       || SQLERRM,
                       1,
                       gc_max_err_size);
            exiting_sub(p_procedure_name      => lc_procedure_name,
                        p_exception_flag      => TRUE);
            RETURN gc_ret_others;
    END get_acct_nums_from_file;

    /********************************************************************
    * Wrapper function to call seeded ap_web_credit_card_pkg.get_card_id.
    *
    * Note, Given an unencrypted credit card number
    *       ap_web_credit_card_pkg.get_card_id will:
    *
    *       1) Card Exists
    *          a) Returns instrument id of an existing credit card
    *       2) Card Does Not Exist
    *          a) Creates a new credit card instrument
    *          b) Returns the card id of a the new credit card
    ********************************************************************/
    FUNCTION get_create_credit_card(
        p_credit_card_number  IN      iby_creditcard.ccnumber%TYPE,
        p_card_program_id     IN      ap_card_programs_all.card_program_id%TYPE,
        x_card_id             OUT     ap_cards_all.card_id%TYPE,
        x_error_message       OUT     VARCHAR2)
        RETURN VARCHAR2
    IS
        PRAGMA AUTONOMOUS_TRANSACTION;
        lc_procedure_name  CONSTANT VARCHAR2(60)        :=    gc_package_name
                                                           || '.'
                                                           || 'get_create_credit_card';
        lt_parameters               gt_input_parameters;
        le_api_exception            EXCEPTION;
    BEGIN
        lt_parameters('p_credit_card_number') :=    gc_credit_card_prefix
                                                 || SUBSTR(p_credit_card_number,
                                                           -4);
        lt_parameters('p_card_program_id') := p_card_program_id;
        entering_sub(p_procedure_name      => lc_procedure_name,
                     p_parameters          => lt_parameters);
        x_card_id :=
            ap_web_credit_card_pkg.get_card_id(p_card_number          => p_credit_card_number,
                                               p_card_program_id      => p_card_program_id);
        logit(p_message      =>    '(RESULTS) x_card_id = '
                                || x_card_id);

        IF (x_card_id = -1)
        THEN
            x_error_message := 'Error: ap_web_credit_card_pkg.get_card_id was unable to get/create credit card.';
            RAISE le_api_exception;
        END IF;

        COMMIT;
        exiting_sub(p_procedure_name      => lc_procedure_name);
        RETURN gc_ret_success;
    EXCEPTION
        WHEN le_api_exception
        THEN
            ROLLBACK;
            x_error_message := SUBSTR(   lc_procedure_name
                                      || ' '
                                      || x_error_message,
                                      1,
                                      gc_max_err_size);
            exiting_sub(p_procedure_name      => lc_procedure_name,
                        p_exception_flag      => TRUE);
            RETURN gc_ret_api;
        WHEN OTHERS
        THEN
            ROLLBACK;
            x_error_message :=
                    SUBSTR(   lc_procedure_name
                           || ' SQLCODE: '
                           || SQLCODE
                           || ' SQLERRM: '
                           || SQLERRM,
                           1,
                           gc_max_err_size);
            exiting_sub(p_procedure_name      => lc_procedure_name,
                        p_exception_flag      => TRUE);
            RETURN gc_ret_others;
    END get_create_credit_card;

    /****************************************************************
    * Helper function to return instrument id given a given card_id
    ****************************************************************/
    FUNCTION get_instrument_id(
        p_card_id        IN      ap_cards_all.card_id%TYPE,
        x_instrument_id  OUT     iby_creditcard.instrid%TYPE,
        x_error_message  OUT     VARCHAR2)
        RETURN VARCHAR2
    IS
        lc_procedure_name  CONSTANT VARCHAR2(60)        :=    gc_package_name
                                                           || '.'
                                                           || 'get_instrument_id';
        lt_parameters               gt_input_parameters;
    BEGIN
        lt_parameters('p_card_id') := p_card_id;
        entering_sub(p_procedure_name      => lc_procedure_name,
                     p_parameters          => lt_parameters);

        SELECT card_reference_id
        INTO   x_instrument_id
        FROM   ap_cards_all
        WHERE  card_id = p_card_id;

        logit(p_message      =>    '(RESULTS) x_instrument_id = '
                                || x_instrument_id);
        exiting_sub(p_procedure_name      => lc_procedure_name);
        RETURN gc_ret_success;
    EXCEPTION
        WHEN NO_DATA_FOUND
        THEN
            x_error_message :=
                    SUBSTR(   lc_procedure_name
                           || ' SQLCODE: '
                           || SQLCODE
                           || ' SQLERRM: '
                           || SQLERRM,
                           1,
                           gc_max_err_size);
            exiting_sub(p_procedure_name      => lc_procedure_name,
                        p_exception_flag      => TRUE);
            RETURN gc_ret_no_data_found;
        WHEN TOO_MANY_ROWS
        THEN
            x_error_message :=
                    SUBSTR(   lc_procedure_name
                           || ' SQLCODE: '
                           || SQLCODE
                           || ' SQLERRM: '
                           || SQLERRM,
                           1,
                           gc_max_err_size);
            exiting_sub(p_procedure_name      => lc_procedure_name,
                        p_exception_flag      => TRUE);
            RETURN gc_ret_too_many_rows;
        WHEN OTHERS
        THEN
            x_error_message :=
                    SUBSTR(   lc_procedure_name
                           || ' SQLCODE: '
                           || SQLCODE
                           || ' SQLERRM: '
                           || SQLERRM,
                           1,
                           gc_max_err_size);
            exiting_sub(p_procedure_name      => lc_procedure_name,
                        p_exception_flag      => TRUE);
            RETURN gc_ret_others;
    END get_instrument_id;

    /****************************************************************
    * Wrapper function to call seeded iby_fndcpt_setup_pub.get_card.
    *
    * Note, Given an instrument id iby_fndcpt_setup_pub.get_card will
    * return a record with the credit card information.
    *****************************************************************/
    FUNCTION get_credit_card(
        p_instrument_id  IN      iby_creditcard.instrid%TYPE,
        x_card_info      OUT     iby_creditcard%ROWTYPE,
        x_error_message  OUT     VARCHAR2)
        RETURN VARCHAR2
    IS
        lc_procedure_name  CONSTANT VARCHAR2(60)        :=    gc_package_name
                                                           || '.'
                                                           || 'get_credit_card';
        lt_parameters               gt_input_parameters;
    BEGIN
        lt_parameters('p_instrument_id') := p_instrument_id;
        entering_sub(p_procedure_name      => lc_procedure_name,
                     p_parameters          => lt_parameters);

        SELECT *
        INTO   x_card_info
        FROM   iby_creditcard
        WHERE  instrid = p_instrument_id;

        logit(p_message      =>    '(RESULTS) Number of records found: '
                                || SQL%ROWCOUNT);
        exiting_sub(p_procedure_name      => lc_procedure_name);
        RETURN gc_ret_success;
    EXCEPTION
        WHEN NO_DATA_FOUND
        THEN
            x_error_message :=
                    SUBSTR(   lc_procedure_name
                           || ' SQLCODE: '
                           || SQLCODE
                           || ' SQLERRM: '
                           || SQLERRM,
                           1,
                           gc_max_err_size);
            exiting_sub(p_procedure_name      => lc_procedure_name,
                        p_exception_flag      => TRUE);
            RETURN gc_ret_no_data_found;
        WHEN TOO_MANY_ROWS
        THEN
            x_error_message :=
                    SUBSTR(   lc_procedure_name
                           || ' SQLCODE: '
                           || SQLCODE
                           || ' SQLERRM: '
                           || SQLERRM,
                           1,
                           gc_max_err_size);
            exiting_sub(p_procedure_name      => lc_procedure_name,
                        p_exception_flag      => TRUE);
            RETURN gc_ret_too_many_rows;
        WHEN OTHERS
        THEN
            x_error_message :=
                    SUBSTR(   lc_procedure_name
                           || ' SQLCODE: '
                           || SQLCODE
                           || ' SQLERRM: '
                           || SQLERRM,
                           1,
                           gc_max_err_size);
            exiting_sub(p_procedure_name      => lc_procedure_name,
                        p_exception_flag      => TRUE);
            RETURN gc_ret_others;
    END get_credit_card;

    /********************************************************************
    * This function takes an unencrypted credit card number returns
    * the encrypted credit card number along with the key used to encrypt
    * the credit card.
    ********************************************************************/
    FUNCTION encrypt_credit_card(
        p_credit_card_number      IN      iby_creditcard.ccnumber%TYPE,
        x_credit_card_number_enc  OUT     iby_creditcard.attribute4%TYPE,
        x_identifier              OUT     iby_creditcard.attribute5%TYPE,
        x_error_message           OUT     VARCHAR2)
        RETURN VARCHAR2
    AS
        lc_procedure_name  CONSTANT VARCHAR2(60)        :=    gc_package_name
                                                           || '.'
                                                           || 'encrypt_credit_card';
        lt_parameters               gt_input_parameters;
        lc_action                   VARCHAR2(1000);
        le_process_exception        EXCEPTION;
    BEGIN
        lt_parameters('p_credit_card_number') :=    gc_credit_card_prefix
                                                 || SUBSTR(p_credit_card_number,
                                                           -4);
        entering_sub(p_procedure_name      => lc_procedure_name,
                     p_parameters          => lt_parameters);
        lc_action := 'Running DBMS_SESSION.set_context(namespace => XX_AP_CCIN_CONTEXT ...';
        DBMS_SESSION.set_context(namespace      => 'XX_AP_CCIN_CONTEXT',
                                 ATTRIBUTE      => 'TYPE',
                                 VALUE          => 'EBS');
        lc_action := 'Running xx_od_security_key_pkg.encrypt_outlabel(p_module => AJB ...';
        xx_od_security_key_pkg.encrypt_outlabel(p_module             => 'AJB',
                                                p_key_label          => NULL,
                                                p_algorithm          => '3DES',
                                                p_decrypted_val      => p_credit_card_number,
                                                x_encrypted_val      => x_credit_card_number_enc,
                                                x_error_message      => x_error_message,
                                                x_key_label          => x_identifier);
        logit(p_message      =>    '(RESULTS) x_credit_card_number_enc = '
                                || x_credit_card_number_enc);
        logit(p_message      =>    '(RESULTS) x_identifier = '
                                || x_identifier);

        IF (x_error_message IS NOT NULL)
        THEN
            x_error_message :=
                SUBSTR(   'xx_od_security_key_pkg.encrypt_outlabel returned error: '
                       || x_error_message,
                       1,
                       gc_max_err_size);
            RAISE le_process_exception;
        ELSIF(x_credit_card_number_enc IS NULL OR x_identifier IS NULL)
        THEN
            x_error_message :=
                   'xx_od_security_key_pkg.encrypt_outlabel returned encrypted credit card: '
                || x_credit_card_number_enc
                || ' identifier: '
                || x_identifier;
            RAISE le_process_exception;
        END IF;

        exiting_sub(p_procedure_name      => lc_procedure_name);
        RETURN gc_ret_success;
    EXCEPTION
        WHEN le_process_exception
        THEN
            x_error_message := SUBSTR(   lc_procedure_name
                                      || ' ERROR:'
                                      || x_error_message,
                                      1,
                                      gc_max_err_size);
            exiting_sub(p_procedure_name      => lc_procedure_name,
                        p_exception_flag      => TRUE);
            RETURN gc_ret_api;
        WHEN OTHERS
        THEN
            x_error_message :=
                SUBSTR(   lc_procedure_name
                       || ' Action:'
                       || lc_action
                       || ' SQLCODE: '
                       || SQLCODE
                       || ' SQLERRM: '
                       || SQLERRM,
                       1,
                       gc_max_err_size);
            exiting_sub(p_procedure_name      => lc_procedure_name,
                        p_exception_flag      => TRUE);
            RETURN gc_ret_others;
    END encrypt_credit_card;

    /********************************************************************
    * This function takes the passed in credit card information
    * and makes any necessary updates to the credit card in the database.
    ********************************************************************/
    FUNCTION update_credit_card(
        p_card_info      IN      iby_creditcard%ROWTYPE,
        x_error_message  OUT     VARCHAR2)
        RETURN VARCHAR2
    IS
        lc_procedure_name  CONSTANT VARCHAR2(60)        :=    gc_package_name
                                                           || '.'
                                                           || 'update_credit_card';
        lt_parameters               gt_input_parameters;
        le_api_exception            EXCEPTION;
    BEGIN
        lt_parameters('p_card_info') := 'Record Type';
        lt_parameters('p_card_info.instrid') := p_card_info.instrid;
        lt_parameters('p_card_info.attribute4') := p_card_info.attribute4;
        lt_parameters('p_card_info.attribute5') := p_card_info.attribute5;
        entering_sub(p_procedure_name      => lc_procedure_name,
                     p_parameters          => lt_parameters);

        UPDATE iby_creditcard
        SET ROW = p_card_info
        WHERE  instrid = p_card_info.instrid;

        logit(p_message      =>    '(RESULTS) rows updated: '
                                || SQL%ROWCOUNT);
        exiting_sub(p_procedure_name      => lc_procedure_name);
        RETURN gc_ret_success;
    EXCEPTION
        WHEN le_api_exception
        THEN
            x_error_message := SUBSTR(   lc_procedure_name
                                      || ' '
                                      || x_error_message,
                                      1,
                                      gc_max_err_size);
            exiting_sub(p_procedure_name      => lc_procedure_name,
                        p_exception_flag      => TRUE);
            RETURN gc_ret_api;
        WHEN OTHERS
        THEN
            x_error_message :=
                    SUBSTR(   lc_procedure_name
                           || ' SQLCODE: '
                           || SQLCODE
                           || ' SQLERRM: '
                           || SQLERRM,
                           1,
                           gc_max_err_size);
            exiting_sub(p_procedure_name      => lc_procedure_name,
                        p_exception_flag      => TRUE);
            RETURN gc_ret_others;
    END update_credit_card;

    /**********************************************************
    * Wrapper function to call the seeded concurrent program:
    * MasterCard CDF3 Transaction Loader and Validation Program
    **********************************************************/
    FUNCTION submit_apxmccdf3_conc_prog(
        p_file_name        IN      VARCHAR2,
        p_card_program_id  IN      ap_card_programs_all.card_program_id%TYPE,
        x_error_message    OUT     VARCHAR2)
        RETURN VARCHAR2
    IS
        PRAGMA AUTONOMOUS_TRANSACTION;
        lc_procedure_name  CONSTANT VARCHAR2(60)              :=    gc_package_name
                                                                 || '.'
                                                                 || 'submit_apxmccdf3_conc_prog';
        lt_parameters               gt_input_parameters;
        ln_request_id               fnd_concurrent_requests.request_id%TYPE;
        le_api_exception            EXCEPTION;
        lc_phase                    fnd_lookups.meaning%TYPE;
        lc_status                   fnd_lookups.meaning%TYPE;
        lc_dev_phase                fnd_lookups.meaning%TYPE;
        lc_dev_status               fnd_lookups.meaning%TYPE;
        lc_message                  VARCHAR2(2000);
        lb_complete                 BOOLEAN                                   := FALSE;
    BEGIN
        lt_parameters('p_file_name') := p_file_name;
        lt_parameters('p_card_program_id') := p_card_program_id;
        entering_sub(p_procedure_name      => lc_procedure_name,
                     p_parameters          => lt_parameters);
        ln_request_id :=
            fnd_request.submit_request(application      => 'SQLAP',
                                       program          => 'APXMCCDF3',
                                       description      => 'MasterCard CDF3 Transaction Loader and Validation Program',
                                       argument1        => p_card_program_id,
                                       argument2        => p_file_name);
        COMMIT;

        IF ln_request_id = 0
        THEN
            RAISE le_api_exception;
        END IF;

        logit(p_message      =>    'Request ID for program short name APXMCCDF3 is: '
                                || ln_request_id);

        IF ln_request_id > 0
        THEN
            lb_complete :=
                fnd_concurrent.wait_for_request(request_id      => ln_request_id,
                                                INTERVAL        => 10,
                                                max_wait        => 7200,
                                                phase           => lc_phase,
                                                status          => lc_status,
                                                dev_phase       => lc_dev_phase,
                                                dev_status      => lc_dev_status,
                                                MESSAGE         => lc_message);
        END IF;

        logit(p_message      =>    'Request phase: '
                                || lc_phase);
        logit(p_message      =>    'Request status: '
                                || lc_status);
        logit(p_message      =>    'Request dev phase: '
                                || lc_dev_phase);
        logit(p_message      =>    'Request dev status: '
                                || lc_dev_phase);
        logit(p_message      =>    'Request message: '
                                || lc_message);
        exiting_sub(p_procedure_name      => lc_procedure_name);
        RETURN gc_ret_success;
    EXCEPTION
        WHEN le_api_exception
        THEN
            x_error_message :=
                SUBSTR(   lc_procedure_name
                       || ' Failure when submitting '
                       || 'MasterCard CDF3 Transaction Loader and Validation Program.'
                       || ' Error: '
                       || fnd_message.get,
                       1,
                       gc_max_err_size);
            exiting_sub(p_procedure_name      => lc_procedure_name,
                        p_exception_flag      => TRUE);
            RETURN gc_ret_api;
        WHEN OTHERS
        THEN
            x_error_message :=
                    SUBSTR(   lc_procedure_name
                           || ' SQLCODE: '
                           || SQLCODE
                           || ' SQLERRM: '
                           || SQLERRM,
                           1,
                           gc_max_err_size);
            exiting_sub(p_procedure_name      => lc_procedure_name,
                        p_exception_flag      => TRUE);
            RETURN gc_ret_others;
    END submit_apxmccdf3_conc_prog;

    /**********************************************************
    * Main program to be called from concurrent manager.
    *
    *   Steps
    *    1. Look for credit card account in file.
    *    2. For each credit card account do the below.
    *    3. Get or create the credit card.
    *    4. Get the credit card information.
    *    5  Check if credit card has been previously encrypted
    *                  using custom encryption.
    *    6. If not previously custom encrypted, encrypt it
    *    7. Update the credit card record with the custom encryption
    *                  information.
    *    8. Submit seeded program to load and valid file
    **********************************************************/
    PROCEDURE process_file(
        x_retcode                     OUT     NUMBER,
        x_errbuf                      OUT     VARCHAR2,
        p_card_program_id             IN      NUMBER,
        p_file_name                   IN      VARCHAR2,
        p_directory                   IN      VARCHAR2,
        p_file_target_node_path       IN      VARCHAR2,
        p_file_target_node_item_name  IN      VARCHAR2,
        p_all_or_nothing_flag         IN      VARCHAR2,
        p_submit_loader_prog          IN      VARCHAR2,
        p_debug_flag                  IN      VARCHAR2)
    AS
        lc_procedure_name  CONSTANT VARCHAR2(60)                          :=    gc_package_name
                                                                             || '.'
                                                                             || 'process_file';
        lt_parameters               gt_input_parameters;
        lc_directory_path           all_directories.directory_path%TYPE;
        lc_credit_card_number       iby_creditcard.ccnumber%TYPE;
        ln_instrument_id            iby_creditcard.instrid%TYPE;
        ln_card_id                  ap_cards_all.card_id%TYPE;
        lr_card_info                iby_creditcard%ROWTYPE;
        lc_credit_card_number_enc   iby_creditcard.attribute4%TYPE;
        lc_identifier               iby_creditcard.attribute5%TYPE;
        lt_account_numbers          gt_account_number;
        lb_all_or_nothing_flag      BOOLEAN                               := FALSE;
        lc_error_message            VARCHAR2(2000);
        le_account_exception        EXCEPTION;
        le_program_exception        EXCEPTION;
        lc_transaction              VARCHAR2(2000);
        lc_return_status            VARCHAR2(20);
    BEGIN
        x_retcode := 0;
        lt_parameters('p_card_program_id') := p_card_program_id;
        lt_parameters('p_file_name') := p_file_name;
        lt_parameters('p_directory') := p_directory;
        lt_parameters('p_file_target_node_path') := p_file_target_node_path;
        lt_parameters('p_file_target_node_item_name') := p_file_target_node_item_name;
        lt_parameters('p_all_or_nothing_flag') := p_all_or_nothing_flag;
        lt_parameters('p_debug_flag') := p_debug_flag;
        lt_parameters('p_submit_loader_prog') := p_submit_loader_prog;
        entering_main(p_procedure_name       => lc_procedure_name,
                      p_rice_identifier      => 'I2168',
                      p_debug_flag           => p_debug_flag,
                      p_parameters           => lt_parameters);

        /*******************************************************************
        * Determine if all or nothing.
        * If TRUE, in the event one transaction fails, roll everything back.
        * Else FALSE, process and commit any individual transactions
        * that are successful
        ********************************************************************/
        IF (UPPER(p_all_or_nothing_flag) IN('Y', 'YES', 'T', 'TRUE'))
        THEN
            lb_all_or_nothing_flag := TRUE;
        END IF;


        /**********************************************
        * Go full directory path given a directory name
        **********************************************/
        lc_return_status :=
            get_full_directory_path(p_directory_name      => p_directory,
                                    x_directory_path      => lc_directory_path,
                                    x_error_message       => lc_error_message);

        IF lc_return_status != gc_ret_success
        THEN
            RAISE le_program_exception;
        END IF;

        -- V4.0, Calling Standard Program
        /************************************************************************************
        * Check input parameter to determine whether to submit the seeded concurrent program:
        *" MasterCard CDF Transaction Loader and Validation Program"
        ************************************************************************************/
        IF (UPPER(p_submit_loader_prog) IN('Y', 'YES', 'T', 'TRUE'))
        THEN
            lc_return_status :=
                submit_apxmccdf3_conc_prog(p_file_name            =>    lc_directory_path
                                                                     || p_file_name,
                                           p_card_program_id      => p_card_program_id,
                                           x_error_message        => lc_error_message);
            COMMIT;

            IF lc_return_status != gc_ret_success
            THEN
                RAISE le_program_exception;
            END IF;
        END IF;



        /*************************************************
        * Go get all the credit card numbers from the file
        *************************************************/
        lc_return_status :=
            get_acct_nums_from_file(p_directory                       => p_directory,
                                    p_file_name                       => p_file_name,
                                    p_file_target_node_path           => p_file_target_node_path,
                                    p_file_target_node_item_name      => p_file_target_node_item_name,
                                    x_account_numbers                 => lt_account_numbers,
                                    x_error_message                   => lc_error_message);

        IF lc_return_status != gc_ret_success
        THEN
            RAISE le_program_exception;
        END IF;

        /******************************************************************************
        * Check to see if any we found any credit card numbers.
        * If so, we need to do the following for each credit card number.
        * 1. Get or create the credit card.
        * 2. Get the credit card information
        * 3. Check if credit card has been previously encrypted using custom encryption
        * 4. If not previously custom encrypted, encrypt it
        * 5. Update the credit card record with the custom encryption information.
        *******************************************************************************/
        IF lt_account_numbers.COUNT > 0
        THEN
            FOR i IN 1 .. lt_account_numbers.COUNT
            LOOP
                BEGIN
                    lc_transaction :=
                                'Processing account_number: '
                             || gc_credit_card_prefix
                             || SUBSTR(lt_account_numbers(i),
                                       -4);
                    /*******************************
                    * Get or create the credit card.
                    *******************************/
                    lc_return_status :=
                        get_create_credit_card(p_credit_card_number      => lt_account_numbers(i),
                                               p_card_program_id         => p_card_program_id,
                                               x_card_id                 => ln_card_id,
                                               x_error_message           => lc_error_message);

                    IF lc_return_status != gc_ret_success
                    THEN
                        RAISE le_account_exception;
                    END IF;

                    /********************************
                    * Get instrument id given card id
                    ********************************/
                    lc_return_status :=
                        get_instrument_id(p_card_id            => ln_card_id,
                                          x_instrument_id      => ln_instrument_id,
                                          x_error_message      => lc_error_message);

                    IF lc_return_status != gc_ret_success
                    THEN
                        RAISE le_account_exception;
                    END IF;

                    /********************************************************
                    * Given an instrument id, get the credit card information
                    ********************************************************/
                    lc_return_status :=
                        get_credit_card(p_instrument_id      => ln_instrument_id,
                                        x_card_info          => lr_card_info,
                                        x_error_message      => lc_error_message);

                    IF lc_return_status != gc_ret_success
                    THEN
                        RAISE le_account_exception;
                    END IF;

                    logit(p_message      =>    'Current lr_card_info.attribute4: '
                                            || lr_card_info.attribute4);
                    logit(p_message      =>    'Current lr_card_info.attribute5: '
                                            || lr_card_info.attribute5);

                    /******************************************************************************
                    * If attribute4 and attribute5 are NULL, it means we have not custom encrypted.
                    ******************************************************************************/
                    IF (lr_card_info.attribute4 IS NULL OR lr_card_info.attribute5 IS NULL)
                    THEN
                        /************************************************************************************
                        * Given the credit card number, get the encrypted value and the key (identifier) used
                        ************************************************************************************/
                        lc_return_status :=
                            encrypt_credit_card(p_credit_card_number          => lt_account_numbers(i),
                                                x_credit_card_number_enc      => lc_credit_card_number_enc,
                                                x_identifier                  => lc_identifier,
                                                x_error_message               => lc_error_message);

                        IF lc_return_status != gc_ret_success
                        THEN
                            RAISE le_account_exception;
                        END IF;

                        lr_card_info.attribute4 := lc_credit_card_number_enc;
                        lr_card_info.attribute5 := lc_identifier;
                        lr_card_info.last_update_date := SYSDATE;
                        lr_card_info.last_updated_by := NVL(fnd_global.user_id,
                                                            -1);
                        /************************************************************
                        *  Update the credit card with the new encryption information
                        ************************************************************/
                        lc_return_status :=
                                    update_credit_card(p_card_info          => lr_card_info,
                                                       x_error_message      => lc_error_message);

                        IF lc_return_status != gc_ret_success
                        THEN
                            RAISE le_account_exception;
                        END IF;
                    END IF;

                    /***************************************************************************
                    * If it is not all or nothing, then just commit any transaction that passes.
                    ***************************************************************************/
                    IF (lb_all_or_nothing_flag != TRUE)
                    THEN
                        COMMIT;
                    END IF;
                EXCEPTION
                    WHEN le_account_exception
                    THEN
                        ROLLBACK;
                        lc_error_message :=
                            SUBSTR(   'Error in '
                                   || lc_transaction
                                   || ' Message: '
                                   || lc_error_message,
                                   1,
                                   gc_max_log_size);
                        logit(p_message      => lc_error_message,
                              p_force        => TRUE);
                        x_retcode := 1;
                        x_errbuf := SUBSTR(lc_error_message,
                                           1,
                                           gc_max_err_buf_size);

                        /******************************************************
                        * No need to continue if a failure was encountered and
                        * we it is set to be all or nothing.
                        ******************************************************/
                        IF (lb_all_or_nothing_flag)
                        THEN
                            RAISE le_program_exception;
                        END IF;
                    WHEN OTHERS
                    THEN
                        ROLLBACK;
                        lc_error_message :=
                            SUBSTR(   'Error in '
                                   || lc_transaction
                                   || '  '
                                   || lc_procedure_name
                                   || ' SQLCODE: '
                                   || SQLCODE
                                   || ' SQLERRM: '
                                   || SQLERRM,
                                   1,
                                   gc_max_log_size);
                        logit(p_message      => lc_error_message,
                              p_force        => TRUE);
                        x_retcode := 1;
                        x_errbuf := SUBSTR(lc_error_message,
                                           1,
                                           gc_max_err_buf_size);

                        /******************************************************
                        * No need to continue if a failure was encountered and
                        * we it is set to be all or nothing.
                        ******************************************************/
                        IF (lb_all_or_nothing_flag)
                        THEN
                            RAISE le_program_exception;
                        END IF;
                END;
            END LOOP;

            IF (lb_all_or_nothing_flag)
            THEN
                COMMIT;
            END IF;
        END IF;
 
        exiting_sub(p_procedure_name      => lc_procedure_name);
    EXCEPTION
        WHEN le_program_exception
        THEN
            x_retcode := 1;
            x_errbuf := SUBSTR(lc_error_message,
                               1,
                               gc_max_err_buf_size);
            logit(p_message      => lc_error_message,
                  p_force        => TRUE);
            exiting_sub(p_procedure_name      => lc_procedure_name,
                        p_exception_flag      => TRUE);
        WHEN OTHERS
        THEN
            x_retcode := 2;
            lc_error_message :=
                    SUBSTR(   lc_procedure_name
                           || ' SQLCODE: '
                           || SQLCODE
                           || ' SQLERRM: '
                           || SQLERRM,
                           1,
                           gc_max_err_size);
            x_errbuf := SUBSTR(lc_error_message,
                               1,
                               gc_max_err_buf_size);
            logit(p_message      => lc_error_message,
                  p_force        => TRUE);
            exiting_sub(p_procedure_name      => lc_procedure_name,
                        p_exception_flag      => TRUE);
    END process_file;

    /**********************************************************
    * Main program to be called from concurrent manager.
    *
    *   Steps
    *    1. Look for unencrypted employee credit cards
    *    2. For each credit card do the below.
    *    3. Get the credit card information.
    *    4  Encrypt it.
    *    5. Update the credit card record with the custom encryption
    *                  information.
    **********************************************************/
    PROCEDURE encrypt_employee_cards(
        x_retcode              OUT     NUMBER,
        x_errbuf               OUT     VARCHAR2,
        p_all_or_nothing_flag  IN      VARCHAR2,
        p_debug_flag           IN      VARCHAR2)
    AS
        CURSOR emp_cards_cur
        IS
            (SELECT acab.card_number, 
                    ic.instrid
             FROM   iby_creditcard ic,
                    ap_cards_all aca,
                    ap_cards_all_11i_bkp acab
             WHERE  ic.instrid = aca.card_reference_id
             AND    aca.card_id = acab.card_id
             AND    (ic.attribute4 IS NULL OR ic.attribute5 IS NULL)
             AND    acab.card_number IS NOT NULL);

        lc_procedure_name  CONSTANT VARCHAR2(60)                   :=    gc_package_name
                                                                      || '.'
                                                                      || 'encrypt_employee_cards';
        lt_parameters               gt_input_parameters;
        lr_card_info                iby_creditcard%ROWTYPE;
        lc_credit_card_number_enc   iby_creditcard.attribute4%TYPE;
        lc_identifier               iby_creditcard.attribute5%TYPE;
        lb_all_or_nothing_flag      BOOLEAN                          := FALSE;
        lc_error_message            VARCHAR2(2000);
        le_account_exception        EXCEPTION;
        le_program_exception        EXCEPTION;
        lc_transaction              VARCHAR2(2000);
        lc_return_status            VARCHAR2(20);
    BEGIN
        x_retcode := 0;
        lt_parameters('p_all_or_nothing_flag') := p_all_or_nothing_flag;
        lt_parameters('p_debug_flag') := p_debug_flag;
        entering_main(p_procedure_name       => lc_procedure_name,
                      p_rice_identifier      => 'I2168_CONVERSION',
                      p_debug_flag           => p_debug_flag,
                      p_parameters           => lt_parameters);

        /*******************************************************************
        * Determine if all or nothing.
        * If TRUE, in the event one transaction fails, roll everything back.
        * Else FALSE, process and commit any individual transactions
        * that are successful
        ********************************************************************/
        IF (UPPER(p_all_or_nothing_flag) IN('Y', 'YES', 'T', 'TRUE'))
        THEN
            lb_all_or_nothing_flag := TRUE;
        END IF;

        FOR emp_card_rec IN emp_cards_cur
        LOOP
            BEGIN
                lc_transaction :=
                                'Processing account_number: '
                             || gc_credit_card_prefix
                             || SUBSTR(emp_card_rec.card_number,
                                       -4);
                                       
                /********************************************************
                * Given an instrument id, get the credit card information
                ********************************************************/
                lc_return_status :=        
                     get_credit_card(p_instrument_id      => emp_card_rec.instrid,
                                     x_card_info          => lr_card_info,
                                     x_error_message      => lc_error_message);
                                                                            
                IF lc_return_status != gc_ret_success
                THEN
                    RAISE le_account_exception;
                END IF;
                                                      
                /************************************************************************************
                * Given the credit card number, get the encrypted value and the key (identifier) used
                ************************************************************************************/
                lc_return_status :=
                    encrypt_credit_card(p_credit_card_number          => emp_card_rec.card_number,
                                        x_credit_card_number_enc      => lc_credit_card_number_enc,
                                        x_identifier                  => lc_identifier,
                                        x_error_message               => lc_error_message);

                IF lc_return_status != gc_ret_success
                THEN
                    RAISE le_account_exception;
                END IF;
                                                       
                lr_card_info.attribute4 := lc_credit_card_number_enc;
                lr_card_info.attribute5 := lc_identifier;
                lr_card_info.last_update_date := SYSDATE;
                lr_card_info.last_updated_by := NVL(fnd_global.user_id,
                                                    -1);
                                                    
                /************************************************************
                *  Update the credit card with the new encryption information
                ************************************************************/
                lc_return_status := update_credit_card(p_card_info          => lr_card_info,
                                                       x_error_message      => lc_error_message);

                IF lc_return_status != gc_ret_success
                THEN
                    RAISE le_account_exception;
                END IF;

                /***************************************************************************
                * If it is not all or nothing, then just commit any transaction that passes.
                ***************************************************************************/
                IF (lb_all_or_nothing_flag != TRUE)
                THEN
                    COMMIT;
                END IF;
            EXCEPTION
                WHEN le_account_exception
                THEN
                    ROLLBACK;
                    lc_error_message :=
                          SUBSTR(   'Error in '
                                 || lc_transaction
                                 || ' Message: '
                                 || lc_error_message,
                                 1,
                                 gc_max_log_size);
                    logit(p_message      => lc_error_message,
                          p_force        => TRUE);
                    x_retcode := 1;
                    x_errbuf := SUBSTR(lc_error_message,
                                       1,
                                       gc_max_err_buf_size);

                    /******************************************************
                    * No need to continue if a failure was encountered and
                    * we it is set to be all or nothing.
                    ******************************************************/
                    IF (lb_all_or_nothing_flag)
                    THEN
                        RAISE le_program_exception;
                    END IF;
                WHEN OTHERS
                THEN
                    ROLLBACK;
                    lc_error_message :=
                        SUBSTR(   'Error in '
                               || lc_transaction
                               || '  '
                               || lc_procedure_name
                               || ' SQLCODE: '
                               || SQLCODE
                               || ' SQLERRM: '
                               || SQLERRM,
                               1,
                               gc_max_log_size);
                    logit(p_message      => lc_error_message,
                          p_force        => TRUE);
                    x_retcode := 1;
                    x_errbuf := SUBSTR(lc_error_message,
                                       1,
                                       gc_max_err_buf_size);

                    /******************************************************
                    * No need to continue if a failure was encountered and
                    * we it is set to be all or nothing.
                    ******************************************************/
                    IF (lb_all_or_nothing_flag)
                    THEN
                        RAISE le_program_exception;
                    END IF;
            END;
        END LOOP;

        IF (lb_all_or_nothing_flag)
        THEN
            COMMIT;
        END IF;

        exiting_sub(p_procedure_name      => lc_procedure_name);
    EXCEPTION
        WHEN le_program_exception
        THEN
            x_retcode := 1;
            x_errbuf := SUBSTR(lc_error_message,
                               1,
                               gc_max_err_buf_size);
            logit(p_message      => lc_error_message,
                  p_force        => TRUE);
            exiting_sub(p_procedure_name      => lc_procedure_name,
                        p_exception_flag      => TRUE);
        WHEN OTHERS
        THEN
            x_retcode := 2;
            lc_error_message :=
                    SUBSTR(   lc_procedure_name
                           || ' SQLCODE: '
                           || SQLCODE
                           || ' SQLERRM: '
                           || SQLERRM,
                           1,
                           gc_max_err_size);
            x_errbuf := SUBSTR(lc_error_message,
                               1,
                               gc_max_err_buf_size);
            logit(p_message      => lc_error_message,
                  p_force        => TRUE);
            exiting_sub(p_procedure_name      => lc_procedure_name,
                        p_exception_flag      => TRUE);
    END encrypt_employee_cards;
END xx_ap_encrypt_credit_card_pkg;
/