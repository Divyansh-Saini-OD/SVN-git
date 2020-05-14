SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

create or replace PACKAGE BODY xx_ar_subscriptions_mt_pkg
AS
-- +==================================================================================================================+
-- |  Office Depot                                                                                                    |
-- +==================================================================================================================+
-- |  Name:  XX_AR_SUBSCRIPTIONS_MT_PKG                                                                               |
-- |                                                                                                                  |
-- |  Description:  This package body is to process subscription billing                                              |
-- |                                                                                                                  |
-- |  Change Record:                                                                                                  |
-- +==================================================================================================================+
-- | Version     Date         Author                 Remarks                                                          |
-- | =========   ===========  =============          =================================================================|
-- | 1.0         11-DEC-2017  Sreedhar Mohan         Initial version                                                  |
-- | 2.0         03-JAN-2018  Jai Shankar Kumar      Changed incorporated as per MD70                                 |
-- | 3.0         07-MAR-2018  Sahithi Kunuru         Code fixes                                                       |
-- | 4.0         04-APR-2018  JAI_CG                 Modified as per JIRA# 20153                                      |
-- | 5.0         06-JUN-2018  Sahithi K              Modified history payload as per NAIT-42103                       |
-- | 6.0         15-JUN-2018  Sahithi K              Modified email service to trigger for BS                         |
-- |                                                 SKUs as per NAIT-30598                                           |
-- | 7.0         26-JULY-2018 Sahithi K              adding SKU# and amount fields to                                 |
-- |                                                 contract email payload NAIT-52868                                |
-- | 8.0         06-AUG-2018  Sahithi K              added new procedure to fetch SALES                               |
-- |                                                 ACCOUNTING MATRIX information NAIT-55057                         |
-- | 9.0         14-SEP-2018  Sahithi K              code changes to automate card failure flow                       |
-- |                                                 NAIT-59644                                                       |
-- | 10.0        17-OCT-2018  Sahithi K              code changes to remove initial order                             |
-- |                                                 dependency for termination SKU NAIT-65525                        |
-- | 11.0        23-OCT-2018  Sahithi K              code changes for AB customers NAIT-68178                         |
-- | 12.0        26-OCT-2018  Sahithi K              modified payload of recurring email to                           |
-- |                                                 include cancelContractRequest NAIT-69296                         |
-- | 13.0        26-DEC-2018  Sahithi K              AB billing code changes -NAIT-68178                              |
-- |                                                 1.checking credit limit of AB customer                           |
-- |                                                 2.send email to credit dept if credit limit                      |
-- |                                                   is reached                                                     |
-- | 14.0        16-JAN-2019  Punit Gupta            Added new Procedure for NAIT-78415                               |
-- | 15.0        04-FEB-2019  Sahithi K              1.code modification to use contract_id as                        |
-- |                                                 unique instead of contract# NAIT-77723                           |
-- |                                                 2.charge seq =1 for auto renewed SS                              |
-- |                                                 SKU's NAIT-79218                                                 |
-- | 16.0        07-MAR-2019  Sahithi K              modified program_id logic in UPSERT script                       |
-- |                                                 from req_id to con_program_id NAIT-87055                         |
-- | 17.0        09-APR-2019  Sahithi K              modified interface_line_attribute1 with                          |
-- |                                                 order#-inv_seq_counter NAIT-91124                                |
-- | 18.0        15-APR-2019  Sahithi K              trigger payment failure for business select                      |
-- |                                                 customer same as SS SKU's NAIT-84277                             |
-- | 19.0        15-APR-2019  Sahithi K              trigger recurring SUCCESS/FAILURE email                          |
-- |                                                 for auto renewed BS2 contracts NAIT-90173                        |
-- | 20.0        24-APR-2019  Sahithi K              NAIT-85914 1.pass trans_id in payment auth payload               |
-- |
-- |                                                 2.pass wallet_type while inserting data                          |
-- |                                                   into ORDT table based on translation                           |
-- | 21.0        24-APR-2019  Sahithi K              Perform AVS check to get trans_id for                            |
-- |                                                 existing contracts in SCM NAIT-89230                             |
-- | 22.0        24-APR-2019  Sahithi K              Update SCM with trans_id for existing contracts NAIT-89231       |
-- |
-- | 23.0        24-APR-2019  Sahithi K              add close_date field which is received                           |
-- |                                                 from SCM extract NAIT-90255                                      |
-- | 24.0        25-APR-2019  Punit Gupta            Made changes in the send_email_autorenew                         |
-- |                                                 Procedure for NAIT-90171                                         |
-- | 25.0        22-APR-2019  Dattatray Bachate      Added Procedure-xx_ar_subs_payload_purge_prc                     |
-- |                                                 for NAIT-83868-> To purge Subscriptions Payload                  |
-- |                                                 and Error table more than 30 days older data                     |
-- | 26.0        03-MAY-2019  Kayeed Ahmed           Added Procedure-get_store_close_info NAIT-93356                  |
-- |                                                 TO Closed Stores Accounting Remapping                            |
-- | 27.0        13-MAY-2019  Dattatray Bachate      Added Procedure-xx_relocation_store_vald_prc                     |
-- |                                                 Procedure to validate the location in HR                         |
-- | 28.0        20-JUN-2019  Punit Gupta            Added Procedure for Defect# NAIT- 72201                          |
-- |                                                 to update the receipt number for AB customers                    |
-- | 29.0        24-JUL-2019  Arvind K               Modified procedure get_pos_info Added parameter                  |
-- |                                                 p_orig_sys_doc_ref for validating POS orders                     |
-- |                                                 when data is not available in procedure                          |
-- |                                                 xx_ar_pos_inv_order_ref for NAIT-87805                           |
-- | 30.0        24-JUL-2019  Arvind K               Modified procedure get_invoice_line_info Added                   |
-- |                                                 parameter p_cont_line_amt for validating POS                     |
-- |                                                 orders when getting discount amount for the                      |
-- |                                                 same invoice and same item for NAIT-87805                        |
-- | 31.0        25-JUL-2019  Dattatray B/Sahithi K  Added Logic to handle AVS check for NAIT-92855                   |
-- |                                                 get_cc_trans_id_information, send_billing_email                  |
-- | 32.0        25-JUL-2019  Sahithi K              write off INV related to TERMINATED and CLOSED                   |
-- |                                                 contracts in SCM - NAIT-101994                                   |
-- | 33.0        16-AUG-2019  Sahithi K              derive store# based on initial order NAIT-101932                 |
-- | 34.0        25-SEP-2019  Sahithi K              roll back changes for sending AVS decline email NAIT-107547      |
-- |
-- | 35.0        27-SEP-2019  Sahithi K              Recurring Payment Auth without COF Tran ID                       |
-- |                                                 Handling and storing COF Tran ID of first(INITIAL)               |
-- |                                                 successful auth NAIT-107551                                      |
-- | 36.0        07-OCT-2019  Sahithi K              added contractStatus field to contractEmailRequest NAIT-108527   |
-- | 37.0        10-OCT-2019  Sahithi K              Modified cancel_date while triggering TERMINATE email-NAIT-110748|
-- | 38.0        18-DEC-2019  Sahithi K              NAIT-117540 45 Day Renewal Notification Email Logic Fix          |
-- | 39.0        16-JAN-2020  Arvind K               NAIT-118527 OD AR Recurring Billing Contract Line                |
-- |                                                 Auto Renewal Failed-EBS PROD                                     |
-- | 40.0        16-JAN-2020  Arvind K               ODNA-164065 EBS Trigger Email For AutoRenew -                    |
-- |                                                 On7DayPaymentFailure,added 'notificationDay' in                  |
-- |                                                 send_billing_email, payload for failure case                     |
-- | 41.0        28-FEB-2020  Kayeed A               NAIT-125675-DataDiscrepancies with renewals billing              |
-- |                                                 add the fix into get_pos_ordt_info                               |
-- | 42.0        03-MAR-2020  Kayeed A               NAIT-125836-Invoice creation is failing with                     |
-- |                                                 no_data_found trying to find the initial POS order               |
-- | 43.0        06-MAR-2020  Kayeed A               NAIT-126620-We need to pass p_contract_info.                     |
-- |                                                 initial_order_number instead of lr_pos_info.sales_order          |
-- | 44.0        05-MAR-2020  Arvind K               NAIT-120499 - EBS 45day analysis-Send email trigger for "Optional|
-- |                                                 alternates" to ODEN when SKU is NOT discontinued/Linked SKU      |
-- | 45.0        05-MAR-2020  Arvind K               NAIT-120554 - EBS: 45 day analysis- Send email trigger for       |
-- |                                                 "Optional alternates" to ODEN when SKU is Discontinued           |
-- | 46.0        05-MAR-2020  Kayeed A               NAIT-117211 -EBS: 45 day analysis- Send email trigger for "Forced|
-- |                                                 alternate" contract renewal to ODEN when SKU is Discontinued     |
-- | 47.0        05-MAR-2020  Kayeed A               NAIT-121271 - EBS: 45 day analysis- Send contract termination    |
-- |                                                 trigger to ODEN (to send email notification to customers) when   |
-- |                                                 sku is discontinued and Optional alternate SKUs are NOT available|
-- | 48.0        05-MAR-2020  Arvind K               NAIT-109437 EBS:Consume Update DNR service for discontinued sku's|
-- | 49.0        12-MAR-2020  Arvind K               NAIT-123879-EBSToHaveDiscontinuedSKUDetailsFlag (Is_Discontinued)|
-- |                                                 At Line Level                                                    |
-- | 50.0        12-MAR-2020  Arvind K               NAIT-112737-EBS: Trigger B2B to create a new Order in AOPS for   |
-- |                                                 proposed Renewal of a contract (for Alt SKU) - EBS Task          |
-- | 51.0        17-MAR-2020  Kayeed A               NAIT-127633-EBS: Code changes into PROCEDURE import_contract_info|
-- |                                                 Import ALT Contract DFF line Info From xx_ar_contracts_gtt       |
-- | 52.0        26-MAR-2020  Kayeed A               NAIT-128645-EBS: Added Function get_cust_profile_info to get BSD |
-- |                                                 customer profile and customer type info                          |
-- | 53.0        26-MAR-2020  Arvind K               NAIT-112711-EBS: Forced Alt - Trigger EAI to send Forced SKU     |
-- |                                                 (for a discontinued SKU) in SCM in a new DFF  Procedure added as |
-- |                                                 get_alternate_sku_info and send_forced_sku_info                  |
-- | 54.0        26-MAR-2020  Kayed A                NAIT-129125-EBS: To add CANCEL_REQUEST_DATE and DNR condition in |
-- |                                                 EBS for Alternative 45 Days notification.Added logic in Procedure|
-- |                                                 send_email_autorenew                                             |
-- | 55.0        16-APR-2020  Kayed A                NAIT-127988:Added condition in import_contract_info procedure for|
-- |                                                 Service Subscriptions:Sales Employee Ids with the string "null"  |
-- |                                                 for POS Oders                                                    |
-- | 56.0        11-MAR-2020  Dattatray B            NAIT-120608 to fix multi rows return error in get_               |
-- |                                                 invoice_dist_info proc while creating rec invoice                |
-- | 57.0        29-APR-2020  Arvind K               Chanes in populateinv for JIRA#NAIT-112423 and NAIT-101932-Recurr|
-- |                                                 Shred Orders- Sales Location Discrepancy between SC Sales Detail |
-- +==================================================================================================================+

  gc_package_name        CONSTANT all_objects.object_name%TYPE   := 'xx_ar_subscriptions_mt_pkg';
  gc_ret_success         CONSTANT VARCHAR2(20)                   := 'SUCCESS';
  gc_ret_no_data_found   CONSTANT VARCHAR2(20)                   := 'NO_DATA_FOUND';
  gc_ret_too_many_rows   CONSTANT VARCHAR2(20)                   := 'TOO_MANY_ROWS';
  gc_ret_api             CONSTANT VARCHAR2(20)                   := 'API';
  gc_ret_others          CONSTANT VARCHAR2(20)                   := 'OTHERS';
  gc_max_err_size        CONSTANT NUMBER                         := 2000;
  gc_max_sub_err_size    CONSTANT NUMBER                         := 256;
  --gc_max_log_size        CONSTANT NUMBER                         := 2000;
  gc_max_log_size        CONSTANT NUMBER                         := 30000;
  gc_max_err_buf_size    CONSTANT NUMBER                         := 250;
  gb_debug                        BOOLEAN                        := FALSE;
  gc_order_source_spc             oe_order_sources.name%TYPE     := 'SPC';
  gc_contract_status     CONSTANT VARCHAR2(20)                   := 'TERMINATE';
  gc_store_number        VARCHAR2(50);
  gc_max_print_size      CONSTANT NUMBER                         := 2000;
  
  TYPE gt_input_parameters IS TABLE OF VARCHAR2(32000)
   INDEX BY VARCHAR2(255);

  TYPE gt_translation_values IS TABLE OF xx_fin_translatevalues.target_value1%TYPE
  INDEX BY VARCHAR2(30);

  TYPE subscription_table IS TABLE OF xx_ar_subscriptions%ROWTYPE
   INDEX BY PLS_INTEGER;
   
   TYPE alt_sku_table IS TABLE OF xx_od_oks_alt_sku_tbl%ROWTYPE
   INDEX BY PLS_INTEGER;

  TYPE item_cost_tab IS TABLE OF NUMBER
   INDEX BY VARCHAR2(30);
   
  /***********************************************
  *  Setter procedure for gb_debug global variable
  *  used for controlling debugging
  ***********************************************/

  PROCEDURE set_debug(p_debug_flag  IN  VARCHAR2)
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

  PROCEDURE logit(p_message  IN  CLOB,
                  p_force    IN  BOOLEAN DEFAULT FALSE)
  IS
    lc_message  CLOB := NULL;
  BEGIN
    --if debug is on (defaults to true)
    IF (gb_debug OR p_force)
    THEN
      lc_message := SUBSTR(TO_CHAR(SYSTIMESTAMP, 'MM/DD/YYYY HH24:MI:SS.FF')
                         || ' => ' || p_message, 1, gc_max_log_size);

      -- if in concurrent program, print to log file
      IF (fnd_global.conc_request_id > 0)
      THEN
        fnd_file.put_line(fnd_file.LOG, lc_message);
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

  PROCEDURE entering_sub(p_procedure_name  IN  VARCHAR2,
                         p_parameters      IN  gt_input_parameters)
  AS
    ln_counter            NUMBER        := 0;
    lc_current_parameter  VARCHAR2(32000) := NULL;
  BEGIN
    IF gb_debug
    THEN
      logit(p_message      => '-----------------------------------------------');
      logit(p_message      =>    'Entering: ' || p_procedure_name);
      lc_current_parameter := p_parameters.FIRST;

      IF p_parameters.COUNT > 0
      THEN
        logit(p_message      => 'Input parameters:');

        LOOP
          EXIT WHEN lc_current_parameter IS NULL;
          ln_counter :=   ln_counter + 1;
          logit(p_message => ln_counter || '. ' || lc_current_parameter || ' => ' || p_parameters(lc_current_parameter));
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

  PROCEDURE entering_main(p_procedure_name   IN  VARCHAR2,
                          p_rice_identifier  IN  VARCHAR2,
                          p_debug_flag       IN  VARCHAR2,
                          p_parameters       IN  gt_input_parameters)
  AS
  BEGIN
    set_debug(p_debug_flag => p_debug_flag);

    IF gb_debug
    THEN
      IF p_rice_identifier IS NOT NULL
      THEN
        logit(p_message      => '-----------------------------------------------');
        logit(p_message      => '-----------------------------------------------');
        logit(p_message      =>    'RICE ID: ' || p_rice_identifier);
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

  PROCEDURE exiting_sub(p_procedure_name  IN  VARCHAR2,
                        p_exception_flag  IN  BOOLEAN DEFAULT FALSE)
  AS
  BEGIN
    IF gb_debug
    THEN
      IF p_exception_flag
      THEN
        logit(p_message => 'Exiting Exception: ' || p_procedure_name);
      ELSE
        logit(p_message => 'Exiting: ' || p_procedure_name);
      END IF;

      logit(p_message      => '-----------------------------------------------');
    END IF;
  EXCEPTION
      WHEN OTHERS
      THEN
          NULL;
  END exiting_sub;

  /************************************************
  * Helper procedure to get translation information
  ************************************************/

  PROCEDURE get_translation_info(p_translation_name  IN            xx_fin_translatedefinition.translation_name%TYPE,
                                 px_translation_info IN OUT NOCOPY xx_fin_translatevalues%ROWTYPE)
  IS

    lc_procedure_name  CONSTANT VARCHAR2(61) := gc_package_name || '.' || 'get_translation_info';
    lt_parameters      gt_input_parameters;

    lr_translation_info xx_fin_translatevalues%ROWTYPE;

  BEGIN

    lt_parameters('p_transalation_name')               := p_translation_name;
    lt_parameters('px_translation_info.source_value1') := px_translation_info.source_value1;
    lt_parameters('px_translation_info.source_value2') := px_translation_info.source_value2;
    lt_parameters('px_translation_info.source_value3') := px_translation_info.source_value3;
    lt_parameters('px_translation_info.source_value4') := px_translation_info.source_value4;

    entering_sub(p_procedure_name  => lc_procedure_name,
                 p_parameters      => lt_parameters);

    SELECT  vals.*
    INTO    lr_translation_info
    FROM    xx_fin_translatevalues vals,
            xx_fin_translatedefinition defn
    WHERE   defn.translate_id                        = vals.translate_id
    AND     defn.translation_name                    = p_translation_name
    AND     NVL(vals.source_value1, '-X')            = NVL(px_translation_info.source_value1, NVL(vals.source_value1, '-X'))
    AND     NVL(vals.source_value2, '-X')            = NVL(px_translation_info.source_value2, NVL(vals.source_value2, '-X'))
    AND     NVL(vals.source_value3, '-X')            = NVL(px_translation_info.source_value3, NVL(vals.source_value3, '-X'))
    AND     NVL(vals.source_value4, '-X')            = NVL(px_translation_info.source_value4, NVL(vals.source_value4, '-X'))
    AND     NVL(vals.source_value5, '-X')            = NVL(px_translation_info.source_value5, NVL(vals.source_value5, '-X'))
    AND     NVL(vals.source_value6, '-X')            = NVL(px_translation_info.source_value6, NVL(vals.source_value6, '-X'))
    AND     NVL(vals.source_value7, '-X')            = NVL(px_translation_info.source_value7, NVL(vals.source_value7, '-X'))
    AND     NVL(vals.source_value8, '-X')            = NVL(px_translation_info.source_value8, NVL(vals.source_value8, '-X'))
    AND     SYSDATE BETWEEN vals.start_date_active AND NVL(vals.end_date_active, SYSDATE + 1)
    AND     SYSDATE BETWEEN defn.start_date_active AND NVL(defn.end_date_active, SYSDATE + 1)
    AND     vals.enabled_flag                        = 'Y'
    AND     defn.enabled_flag                        = 'Y';

    px_translation_info := lr_translation_info;
    
    logit(p_message => 'RESULT target_value1: ' || px_translation_info.target_value1);

    exiting_sub(p_procedure_name => lc_procedure_name);

    EXCEPTION
    WHEN OTHERS
    THEN
      exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => TRUE);
      RAISE_APPLICATION_ERROR(-20101, 'PROCEDURE: ' || lc_procedure_name || ' SQLCODE: ' || SQLCODE || ' SQLERRM: ' || SQLERRM);

  END get_translation_info;
  
  /************************************************************
  * Helper procedure to get sales accounting matrix information
  ************************************************************/

  PROCEDURE get_sales_acct_matrix_info(p_translation_name  IN            xx_fin_translatedefinition.translation_name%TYPE,
                                       px_translation_info IN OUT NOCOPY xx_fin_translatevalues%ROWTYPE)
  IS

    lc_procedure_name  CONSTANT VARCHAR2(61) := gc_package_name || '.' || 'get_sales_acct_matrix_info';
    lt_parameters      gt_input_parameters;

    lr_translation_info xx_fin_translatevalues%ROWTYPE;

  BEGIN

    lt_parameters('p_transalation_name')               := p_translation_name;
    lt_parameters('px_translation_info.source_value1') := px_translation_info.source_value1;
    lt_parameters('px_translation_info.source_value2') := px_translation_info.source_value2;
    lt_parameters('px_translation_info.source_value3') := px_translation_info.source_value3;
    lt_parameters('px_translation_info.source_value4') := px_translation_info.source_value4;

    entering_sub(p_procedure_name  => lc_procedure_name,
                 p_parameters      => lt_parameters);

    SELECT  vals.*
    INTO    lr_translation_info
    FROM    xx_fin_translatevalues vals,
            xx_fin_translatedefinition defn
    WHERE   defn.translate_id                        = vals.translate_id
    AND     defn.translation_name                    = p_translation_name
    AND     NVL(vals.source_value1, '-X')            = NVL(px_translation_info.source_value1, '-X')
    AND     NVL(vals.source_value2, '-X')            = NVL(px_translation_info.source_value2, '-X')
    AND     NVL(vals.source_value3, '-X')            = NVL(px_translation_info.source_value3, '-X')
    AND     NVL(vals.source_value4, '-X')            = NVL(px_translation_info.source_value4, '-X')
    AND     NVL(vals.source_value5, '-X')            = NVL(px_translation_info.source_value5, '-X')
    AND     NVL(vals.source_value6, '-X')            = NVL(px_translation_info.source_value6, '-X')
    AND     NVL(vals.source_value7, '-X')            = NVL(px_translation_info.source_value7, '-X')
    AND     NVL(vals.source_value8, '-X')            = NVL(px_translation_info.source_value8, '-X')
    AND     SYSDATE BETWEEN vals.start_date_active AND NVL(vals.end_date_active, SYSDATE + 1)
    AND     SYSDATE BETWEEN defn.start_date_active AND NVL(defn.end_date_active, SYSDATE + 1)
    AND     vals.enabled_flag                        = 'Y'
    AND     defn.enabled_flag                        = 'Y';

    px_translation_info := lr_translation_info;
    
    logit(p_message => 'RESULT target_value1: ' || px_translation_info.target_value1);

    exiting_sub(p_procedure_name => lc_procedure_name);

    EXCEPTION
    WHEN OTHERS
    THEN
      exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => TRUE);
      RAISE_APPLICATION_ERROR(-20101, 'PROCEDURE: ' || lc_procedure_name || ' SQLCODE: ' || SQLCODE || ' SQLERRM: ' || SQLERRM);

  END get_sales_acct_matrix_info;
  
  /**************************************************************************
  * Helper procedure to get day information on which auth should be performed
  **************************************************************************/

  PROCEDURE get_auth_day_info(p_auth_day IN OUT NOCOPY NUMBER)
  IS

    lc_procedure_name  CONSTANT VARCHAR2(61) := gc_package_name || '.' || 'get_auth_day_info';

  BEGIN
    BEGIN
      SELECT  DISTINCT TO_NUMBER(vals.source_value2)
      INTO    p_auth_day
      FROM    xx_fin_translatevalues vals,
              xx_fin_translatedefinition defn
      WHERE   defn.translate_id                        =  vals.translate_id
      AND     defn.translation_name                    =  'SUBSCRIPTION_CC_FAIL_FLOW'
      AND     TO_NUMBER(vals.source_value2)            =  p_auth_day
      AND     SYSDATE BETWEEN vals.start_date_active AND NVL(vals.end_date_active, SYSDATE + 1)
      AND     SYSDATE BETWEEN defn.start_date_active AND NVL(defn.end_date_active, SYSDATE + 1)
      AND     vals.enabled_flag                        = 'Y'
      AND     defn.enabled_flag                        = 'Y';

    EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
        p_auth_day := -1;
      WHEN OTHERS
      THEN
        p_auth_day := -1;
    END;

    exiting_sub(p_procedure_name => lc_procedure_name);

  EXCEPTION
    WHEN OTHERS
    THEN
      exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => TRUE);
      RAISE_APPLICATION_ERROR(-20101, 'PROCEDURE: ' || lc_procedure_name || ' SQLCODE: ' || SQLCODE || ' SQLERRM: ' || SQLERRM);

  END get_auth_day_info;
  
  /******************************************
  * Helper procedure to get auth failure flow 
  ******************************************/

  PROCEDURE get_auth_fail_info(p_payment_status    IN         xx_ar_subscriptions.payment_status%TYPE,
                               p_auth_day          IN         NUMBER,
                               px_translation_info OUT NOCOPY xx_fin_translatevalues%ROWTYPE)
  IS

    lc_procedure_name  CONSTANT VARCHAR2(61) := gc_package_name || '.' || 'get_auth_fail_info';
    lt_parameters      gt_input_parameters;

    lr_translation_info xx_fin_translatevalues%ROWTYPE;

  BEGIN

    lt_parameters('p_payment_status')   := p_payment_status;
    lt_parameters('p_auth_day')         := p_auth_day;
   

    entering_sub(p_procedure_name  => lc_procedure_name,
                 p_parameters      => lt_parameters);

    SELECT  vals.*
    INTO    lr_translation_info
    FROM    xx_fin_translatevalues vals,
            xx_fin_translatedefinition defn
    WHERE   defn.translate_id                 =  vals.translate_id
    AND     defn.translation_name             =  'SUBSCRIPTION_CC_FAIL_FLOW'
    AND     vals.source_value1                =  p_payment_status
    AND     p_auth_day BETWEEN TO_NUMBER(vals.source_value2) AND TO_NUMBER(vals.source_value3) 
    AND     SYSDATE BETWEEN vals.start_date_active AND  NVL(vals.end_date_active, SYSDATE + 1)
    AND     SYSDATE BETWEEN defn.start_date_active AND  NVL(defn.end_date_active, SYSDATE + 1)
    AND     vals.enabled_flag                        = 'Y'
    AND     defn.enabled_flag                        = 'Y';

    px_translation_info := lr_translation_info;
    
    logit(p_message => 'RESULT target_value1: ' || px_translation_info.target_value1);
    logit(p_message => 'RESULT target_value2: ' || px_translation_info.target_value2);

    exiting_sub(p_procedure_name => lc_procedure_name);

    EXCEPTION
    WHEN OTHERS
    THEN
      exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => TRUE);
      RAISE_APPLICATION_ERROR(-20101, 'PROCEDURE: ' || lc_procedure_name || ' SQLCODE: ' || SQLCODE || ' SQLERRM: ' || SQLERRM);

  END get_auth_fail_info;

  /***********************************************
  * Helper procedure to get all the program setups
  ***********************************************/

  PROCEDURE get_program_setups(x_program_setups OUT NOCOPY gt_translation_values)
  IS

    lc_procedure_name  CONSTANT VARCHAR2(61) := gc_package_name || '.' || 'get_program_setups';
    lt_parameters      gt_input_parameters;

    lc_action            VARCHAR2(1000);

    lc_current_value     xx_fin_translatevalues.target_value1%TYPE;

    lt_translation_info xx_fin_translatevalues%ROWTYPE;

  BEGIN

    entering_sub(p_procedure_name  => lc_procedure_name,
                 p_parameters      => lt_parameters);

    /*****************
    * Get enable debug
    *****************/

    lc_action :=  'Calling get_translation_info for enable_debug';

    lt_translation_info := NULL;

    lt_translation_info.source_value1 := 'ENABLE_DEBUG';

    get_translation_info(p_translation_name  => 'XX_AR_SUBSCRIPTIONS',
                         px_translation_info => lt_translation_info);

    x_program_setups('enable_debug') := lt_translation_info.target_value1;

    /****************
    * Get RMS DB LINK
    ****************/

    lc_action :=  'Calling get_translation_info for x_rms_dba_link';

    lt_translation_info := NULL;

    lt_translation_info.source_value1 := 'RMS_DB_LINK';

    get_translation_info(p_translation_name  => 'XX_AR_SUBSCRIPTIONS',
                         px_translation_info => lt_translation_info);

    x_program_setups('rms_dba_link') := lt_translation_info.target_value1;

    /*********************
    * Get tax enabled flag
    *********************/

    lc_action :=  'Calling get_translation_info for tax service';

    lt_translation_info := NULL;

    lt_translation_info.source_value1 := 'ENABLE_TAX';

    get_translation_info(p_translation_name  => 'XX_AR_SUBSCRIPTIONS',
                         px_translation_info => lt_translation_info);

    x_program_setups('tax_enabled_flag') := lt_translation_info.target_value1;
    
    /***********************
    * Get transaction source
    ***********************/

    lc_action :=  'Calling get_translation_info for transaction source';

    lt_translation_info := NULL;

    get_translation_info(p_translation_name  => 'OD_AR_BILLING_SOURCE_EXCL',
                         px_translation_info => lt_translation_info);

     x_program_setups('order_source_id_pro') := lt_translation_info.source_value4;
     x_program_setups('order_source_id_poe') := lt_translation_info.source_value2;     

    /****************************
    * Get tax service information
    ****************************/

    IF x_program_setups('tax_enabled_flag') = 'Y'
    THEN

      lc_action :=  'Calling get_translation_info for tax service info';

      lt_translation_info := NULL;

      lt_translation_info.source_value1 := 'TAX_SERVICE';

      get_translation_info(p_translation_name  => 'XX_AR_SUBSCRIPTIONS',
                           px_translation_info => lt_translation_info);

      x_program_setups('tax_service_url')  := lt_translation_info.target_value1;
      x_program_setups('tax_service_user') := lt_translation_info.target_value2;
      x_program_setups('tax_service_pwd')  := lt_translation_info.target_value3;
    END IF;
    
    /*********************************
    * Get BS email service information
    *********************************/

    lc_action :=  'Calling get_translation_info for email service info';

    lt_translation_info := NULL;

    lt_translation_info.source_value1 := 'BS_EMAIL_SERVICE';

    get_translation_info(p_translation_name  => 'XX_AR_SUBSCRIPTIONS',
                         px_translation_info => lt_translation_info);

    x_program_setups('bs_email_service_url')  := lt_translation_info.target_value1;
    x_program_setups('bs_email_service_user') := lt_translation_info.target_value2;
    x_program_setups('bs_email_service_pwd')  := lt_translation_info.target_value3;

    /*****************************
    * Get auth service information
    *****************************/

    lc_action :=  'Calling get_translation_info for auth service info';

    lt_translation_info := NULL;

    lt_translation_info.source_value1 := 'AUTH_SERVICE';

    get_translation_info(p_translation_name  => 'XX_AR_SUBSCRIPTIONS',
                         px_translation_info => lt_translation_info);

    x_program_setups('auth_service_url')  := lt_translation_info.target_value1;
    x_program_setups('auth_service_user') := lt_translation_info.target_value2;
    x_program_setups('auth_service_pwd')  := lt_translation_info.target_value3;

    /************************
    * Get receipt method name
    ************************/

    lc_action :=  'Calling get_translation_info for receipt method name';

    lt_translation_info := NULL;

    lt_translation_info.source_value1 := 'RECEIPT_METHOD';

    get_translation_info(p_translation_name  => 'XX_AR_SUBSCRIPTIONS',
                         px_translation_info => lt_translation_info);

    x_program_setups('receipt_method_name')  := lt_translation_info.target_value1;

    /******************************
    * Get email service information
    ******************************/

    lc_action :=  'Calling get_translation_info for email service info';

    lt_translation_info := NULL;

    lt_translation_info.source_value1 := 'BILL_EMAIL_SERVICE';

    get_translation_info(p_translation_name  => 'XX_AR_SUBSCRIPTIONS',
                         px_translation_info => lt_translation_info);

    x_program_setups('email_service_url')  := lt_translation_info.target_value1;
    x_program_setups('email_service_user') := lt_translation_info.target_value2;
    x_program_setups('email_service_pwd')  := lt_translation_info.target_value3;

    /*******************************************
    * Get auto renewal email service information
    *******************************************/

    lc_action :=  'Calling get_translation_info for auto renewal email service info';

    lt_translation_info := NULL;

    lt_translation_info.source_value1 := 'BILL_AUTORENEWAL_EMAIL_SERVICE';

    get_translation_info(p_translation_name  => 'XX_AR_SUBSCRIPTIONS',
                         px_translation_info => lt_translation_info);

    x_program_setups('autorenew_email_service_url')  := lt_translation_info.target_value1;
    x_program_setups('autorenew_email_service_user') := lt_translation_info.target_value2;
    x_program_setups('autorenew_email_service_pwd')  := lt_translation_info.target_value3;

   /*******************************************
    * Get DNR email service information
    *******************************************/

    lc_action :=  'Calling get_translation_info for DNR email service info';

    lt_translation_info := NULL;

    lt_translation_info.source_value1 := 'DNR_EMAIL_SERVICE';

    get_translation_info(p_translation_name  => 'XX_AR_SUBSCRIPTIONS',
                         px_translation_info => lt_translation_info);

    x_program_setups('dnr_email_service_url')  := lt_translation_info.target_value1;
    x_program_setups('dnr_email_service_user') := lt_translation_info.target_value2;
    x_program_setups('dnr_email_service_pwd')  := lt_translation_info.target_value3;

   /*******************************************
    * Get ALT Forced email service information
    *******************************************/

    lc_action :=  'Calling get_translation_info for ALT Forced SKU email service info';

    lt_translation_info := NULL;

    lt_translation_info.source_value1 := 'ALT_FORCED_SKU';

    get_translation_info(p_translation_name  => 'XX_AR_SUBSCRIPTIONS',
                         px_translation_info => lt_translation_info);

    x_program_setups('alt_forced_sku_email_url')  := lt_translation_info.target_value1;
    x_program_setups('alt_forced_sku_email_user') := lt_translation_info.target_value2;
    x_program_setups('alt_forced_sku_email_pwd')  := lt_translation_info.target_value3;

   /*******************************************
    * Get B2B email service information
    *******************************************/

    lc_action :=  'Calling get_translation_info for B2B email service info';

    lt_translation_info := NULL;

    lt_translation_info.source_value1 := 'B2B_ORDER_CREATION';

    get_translation_info(p_translation_name  => 'XX_AR_SUBSCRIPTIONS',
                         px_translation_info => lt_translation_info);

    x_program_setups('b2b_order_creation')  := lt_translation_info.target_value1;

    /********************************
    * Get history service information
    ********************************/

    lc_action :=  'Calling get_translation_info for history service info';

    lt_translation_info := NULL;

    lt_translation_info.source_value1 := 'BILL_HISTORY_SERVICE';

    get_translation_info(p_translation_name  => 'XX_AR_SUBSCRIPTIONS',
                         px_translation_info => lt_translation_info);

    x_program_setups('history_service_url')  := lt_translation_info.target_value1;
    x_program_setups('history_service_user') := lt_translation_info.target_value2;
    x_program_setups('history_service_pwd')  := lt_translation_info.target_value3;

    /***********************
    * Get wallet information
    ***********************/

    lc_action :=  'Calling get_translation_info for receipt method name';

    lt_translation_info := NULL;

    lt_translation_info.source_value1 := 'WALLET_LOCATION';

    get_translation_info(p_translation_name  => 'XX_FIN_IREC_TOKEN_PARAMS',
                         px_translation_info => lt_translation_info);

    x_program_setups('wallet_location')  := lt_translation_info.target_value1;
    x_program_setups('wallet_password')  := lt_translation_info.target_value2;

    /*************************
    * Get default store number
    *************************/

    lc_action :=  'Calling get_translation_info for default store number';

    lt_translation_info := NULL;

    lt_translation_info.source_value1 := 'SUBSCRIPTIONS_PMT_STORE_NUMBER';

    get_translation_info(p_translation_name  => 'XX_AR_SUBSCRIPTIONS',
                         px_translation_info => lt_translation_info);

    x_program_setups('default_store_name') := lt_translation_info.target_value1;

    /*********************
    * Get transaction type
    *********************/

    lc_action :=  'Calling get_translation_info for transaction type';

    lt_translation_info := NULL;

    lt_translation_info.source_value1 := 'TRANSACTION_TYPE';

    get_translation_info(p_translation_name  => 'XX_AR_SUBSCRIPTIONS',
                         px_translation_info => lt_translation_info);

    x_program_setups('transaction_type') := lt_translation_info.target_value1;

    /***********************
    * Get transaction source
    ***********************/

    lc_action :=  'Calling get_translation_info for transaction source';

    lt_translation_info := NULL;

    lt_translation_info.source_value1 := 'TRANSACTION_SOURCE';

    get_translation_info(p_translation_name  => 'XX_AR_SUBSCRIPTIONS',
                         px_translation_info => lt_translation_info);

    x_program_setups('transaction_source') := lt_translation_info.target_value1;

    /**************
    * Get memo line
    **************/

    lc_action :=  'Calling get_translation_info for memo line';

    lt_translation_info := NULL;

    lt_translation_info.source_value1 := 'MEMO_LINE';

    get_translation_info(p_translation_name  => 'XX_AR_SUBSCRIPTIONS',
                         px_translation_info => lt_translation_info);

    x_program_setups('memo_line') := lt_translation_info.target_value1;

    exiting_sub(p_procedure_name => lc_procedure_name);

    /***************************
    * Get crypto vault directory
    ***************************/

    lc_action :=  'Calling get_translation_info for crypto vault directory';

    lt_translation_info := NULL;

    lt_translation_info.source_value1 := 'CRYPTO_VAULT_DIR';

    get_translation_info(p_translation_name  => 'XX_AR_SUBSCRIPTIONS',
                         px_translation_info => lt_translation_info);

    x_program_setups('crypto_vault_dir') := lt_translation_info.target_value1;

    /********************
    * Get termination SKU
    ********************/

    lc_action :=  'Calling get_translation_info for termination SKU';

    lt_translation_info := NULL;

    lt_translation_info.source_value1 := 'TERMINATION_SKU';

    get_translation_info(p_translation_name  => 'XX_AR_SUBSCRIPTIONS',
                         px_translation_info => lt_translation_info);

    x_program_setups('termination_sku')  := lt_translation_info.target_value1;

    /********************************************
    * Get wallet_type for Subscription Subsequent
    ********************************************/

    lc_action :=  'Calling get_translation_info for Subscription Subsequent';

    lt_translation_info := NULL;

    lt_translation_info.source_value1 := 'SUBSCRIPTION_SUBSEQUENT';

    get_translation_info(p_translation_name  => 'XX_AR_SUBSCRIPTIONS',
                         px_translation_info => lt_translation_info);

    x_program_setups('subscription_subsequent')  := lt_translation_info.target_value1;
    
    /******************************************
    * Get wallet_type for Subscription Resubmit
    ******************************************/
    
    lc_action :=  'Calling get_translation_info for Subscription Resubmit';

    lt_translation_info := NULL;

    lt_translation_info.source_value1 := 'SUBSCRIPTION_RESUBMIT';

    get_translation_info(p_translation_name  => 'XX_AR_SUBSCRIPTIONS',
                         px_translation_info => lt_translation_info);

    x_program_setups('subscription_resubmit')  := lt_translation_info.target_value1;
    
    /**********************************
    * Get AVS check flag for POS orders
    **********************************/
    
    lc_action :=  'Calling get_translation_info for Subscription Resubmit';

    lt_translation_info := NULL;

    lt_translation_info.source_value1 := 'POS_AVS_CHECK_FLAG';

    get_translation_info(p_translation_name  => 'XX_AR_SUBSCRIPTIONS',
                         px_translation_info => lt_translation_info);

    x_program_setups('pos_avs_check_flag')  := lt_translation_info.target_value1;
    
    /********************************************
    * Get update trans_id SCM service information
    ********************************************/

    lc_action :=  'Calling get_translation_info for updating trans_id to SCM service info';

    lt_translation_info := NULL;

    lt_translation_info.source_value1 := 'UPDATE_TRANS_ID_SCM';

    get_translation_info(p_translation_name  => 'XX_AR_SUBSCRIPTIONS',
                         px_translation_info => lt_translation_info);

    x_program_setups('update_trans_id_scm_url')  := lt_translation_info.target_value1;
    x_program_setups('update_trans_id_scm_user') := lt_translation_info.target_value2;
    x_program_setups('update_trans_id_scm_pwd')  := lt_translation_info.target_value3;
    
    /*******************
    * Get COF check flag
    *******************/

    lc_action :=  'Calling get_translation_info for COF check flag';

    lt_translation_info := NULL;

    lt_translation_info.source_value1 := 'COF_CHECK_FLAG';

    get_translation_info(p_translation_name  => 'XX_AR_SUBSCRIPTIONS',
                         px_translation_info => lt_translation_info);

    x_program_setups('cof_check_flag')  := lt_translation_info.target_value1;
    
    /**********************
    * Get rec activity name
    **********************/

    lc_action :=  'Calling get_translation_info for receivable activity name';

    lt_translation_info := NULL;

    lt_translation_info.source_value1 := 'REC_ACTIVITY_NAME';

    get_translation_info(p_translation_name  => 'XX_AR_SUBSCRIPTIONS',
                         px_translation_info => lt_translation_info);

    x_program_setups('rec_activity_name')  := lt_translation_info.target_value1;

    exiting_sub(p_procedure_name => lc_procedure_name);

    EXCEPTION
    WHEN OTHERS
    THEN
      exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => TRUE);
      RAISE_APPLICATION_ERROR(-20101, 'PROCEDURE: ' || lc_procedure_name || ' ACTION: ' || lc_action || ' SQLCODE: ' || SQLCODE || ' SQLERRM: ' || SQLERRM);

  END get_program_setups;

  /****************************************************
  * Helper procedure to get contract header information
  ****************************************************/

  PROCEDURE get_contract_info(p_contract_id     IN         xx_ar_contracts.contract_id%TYPE,
                              x_contract_info   OUT NOCOPY xx_ar_contracts%ROWTYPE)
  IS

    lc_procedure_name  CONSTANT VARCHAR2(61) := gc_package_name || '.' || 'get_contract_info';
    lt_parameters      gt_input_parameters;

  BEGIN

    lt_parameters('p_contract_id') := p_contract_id;

    entering_sub(p_procedure_name  => lc_procedure_name,
                 p_parameters      => lt_parameters);
    SELECT *
    INTO   x_contract_info
    FROM   xx_ar_contracts
    WHERE  contract_id = p_contract_id;

    logit(p_message => 'RESULT contract_number: ' || x_contract_info.contract_number);

    exiting_sub(p_procedure_name => lc_procedure_name);

    EXCEPTION
    WHEN OTHERS
    THEN
      exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => TRUE);
      RAISE_APPLICATION_ERROR(-20101, 'PROCEDURE: ' || lc_procedure_name || ' SQLCODE: ' || SQLCODE || ' SQLERRM: ' || SQLERRM);

  END get_contract_info;

  /**************************************************
  * Helper procedure to get contract line information
  **************************************************/

  PROCEDURE get_contract_line_info(p_contract_id          IN         xx_ar_contract_lines.contract_id%TYPE,
                                   p_contract_line_number IN         xx_ar_contract_lines.contract_line_number%TYPE,
                                   x_contract_line_info   OUT NOCOPY xx_ar_contract_lines%ROWTYPE)
  IS

    lc_procedure_name  CONSTANT VARCHAR2(61) := gc_package_name || '.' || 'get_contract_line_info';
    lt_parameters      gt_input_parameters;

  BEGIN

    lt_parameters('p_contract_id')          := p_contract_id;
    lt_parameters('p_contract_line_number') := p_contract_line_number;

    entering_sub(p_procedure_name  => lc_procedure_name,
                 p_parameters      => lt_parameters);
    SELECT *
    INTO   x_contract_line_info
    FROM   xx_ar_contract_lines
    WHERE  contract_id          = p_contract_id
    AND    contract_line_number = p_contract_line_number;

    logit(p_message => 'RESULT item_name: ' || x_contract_line_info.item_name);

    exiting_sub(p_procedure_name => lc_procedure_name);

    EXCEPTION
    WHEN OTHERS
    THEN
      exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => TRUE);
      RAISE_APPLICATION_ERROR(-20101, 'PROCEDURE: ' || lc_procedure_name || ' SQLCODE: ' || SQLCODE || ' SQLERRM: ' || SQLERRM);

  END get_contract_line_info;

  /***************************************************
  * Helper procedure to get invoice header information
  ***************************************************/

  PROCEDURE get_invoice_header_info(p_invoice_number      IN         ra_customer_trx_all.trx_number%TYPE,
                                    x_invoice_header_info OUT NOCOPY ra_customer_trx_all%ROWTYPE)
  IS

    lc_procedure_name  CONSTANT VARCHAR2(61) := gc_package_name || '.' || 'get_invoice_header_info';
    lt_parameters      gt_input_parameters;

  BEGIN

    lt_parameters('p_invoice_number') := p_invoice_number;

    entering_sub(p_procedure_name  => lc_procedure_name,
                 p_parameters      => lt_parameters);

    SELECT *
    INTO   x_invoice_header_info
    FROM   ra_customer_trx_all
    WHERE  trx_number = p_invoice_number;

    logit(p_message => 'RESULT customer_trx_id: ' || x_invoice_header_info.customer_trx_id);

    exiting_sub(p_procedure_name => lc_procedure_name);

    EXCEPTION
    WHEN OTHERS
    THEN
      exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => TRUE);
      RAISE_APPLICATION_ERROR(-20101, 'PROCEDURE: ' || lc_procedure_name || ' SQLCODE: ' || SQLCODE || ' SQLERRM: ' || SQLERRM);

  END get_invoice_header_info;

  /*********************************************************
  * Helper procedure to get invoice total amount information
  *********************************************************/

  PROCEDURE get_invoice_total_amount_info(p_customer_trx_id           IN         ra_customer_trx_lines_all.customer_trx_id%TYPE,
                                          x_invoice_total_amount_info OUT NOCOPY ra_customer_trx_lines_all.extended_amount%TYPE)
  IS

    lc_procedure_name  CONSTANT VARCHAR2(61) := gc_package_name || '.' || 'get_invoice_total_amount_info';
    lt_parameters      gt_input_parameters;

  BEGIN

    lt_parameters('p_customer_trx_id') := p_customer_trx_id;

    entering_sub(p_procedure_name  => lc_procedure_name,
                 p_parameters      => lt_parameters);

    SELECT SUM(NVL(extended_amount, 0))
    INTO   x_invoice_total_amount_info
    FROM   ra_customer_trx_lines_all
    WHERE  customer_trx_id = p_customer_trx_id;

    logit(p_message => 'RESULT x_invoice_total_amount_info: ' || x_invoice_total_amount_info);

    exiting_sub(p_procedure_name => lc_procedure_name);

    EXCEPTION
    WHEN OTHERS
    THEN
      exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => TRUE);
      RAISE_APPLICATION_ERROR(-20101, 'PROCEDURE: ' || lc_procedure_name || ' SQLCODE: ' || SQLCODE || ' SQLERRM: ' || SQLERRM);

  END get_invoice_total_amount_info;

  /*************************************************
  * Helper procedure to get invoice line information
  *************************************************/

  PROCEDURE get_invoice_line_info(p_customer_trx_id   IN         ra_customer_trx_lines_all.customer_trx_id%TYPE,
                                  p_line_number       IN         ra_customer_trx_lines_all.line_number%TYPE,
                                  p_inventory_item_id IN         mtl_system_items_b.inventory_item_id%TYPE,
                                  p_cont_line_amt     IN         xx_ar_subscriptions.contract_line_amount%TYPE,
                                  p_source            IN         xx_ar_contracts.external_source%TYPE,
                                  x_invoice_line_info OUT NOCOPY ra_customer_trx_lines_all%ROWTYPE)
  IS

    lc_procedure_name  CONSTANT VARCHAR2(61) := gc_package_name || '.' || 'get_invoice_line_info';
    lt_parameters      gt_input_parameters;

  BEGIN

    lt_parameters('p_customer_trx_id')   := p_customer_trx_id;
    lt_parameters('p_inventory_item_id') := p_inventory_item_id;
    lt_parameters('p_line_number')       := p_line_number;
    lt_parameters('p_source')            := p_source;

    entering_sub(p_procedure_name  => lc_procedure_name,
                 p_parameters      => lt_parameters);

    IF p_source ='POS'
    THEN
     BEGIN
      SELECT *
      INTO   x_invoice_line_info
      FROM   ra_customer_trx_lines_all
      WHERE  customer_trx_id    = p_customer_trx_id
      AND    inventory_item_id  = p_inventory_item_id
      AND    unit_selling_price = p_cont_line_amt
      AND    line_type          = 'LINE'
      AND    line_number        = p_line_number
     ;
   --begin get_invoice_line_info Error: -20101 ORA-20101: PROCEDURE: xx_ar_subscriptions_mt_pkg.get_invoice_line_info SQLCODE: 100 SQLERRM: ORA-01403: no data found
      EXCEPTION
      WHEN NO_DATA_FOUND THEN
        SELECT *
        INTO   x_invoice_line_info
        FROM   ra_customer_trx_lines_all
        WHERE  customer_trx_id    = p_customer_trx_id
        AND    inventory_item_id  = p_inventory_item_id
    --  AND    unit_selling_price = p_cont_line_amt
        AND    line_type          = 'LINE'
        AND    line_number        = p_line_number
     ;
      END;
    --end get_invoice_line_info Error: -20101 ORA-20101: PROCEDURE: xx_ar_subscriptions_mt_pkg.get_invoice_line_info SQLCODE: 100 SQLERRM: ORA-01403: no data found
    ELSE
      SELECT *
      INTO   x_invoice_line_info
      FROM   ra_customer_trx_lines_all
      WHERE  customer_trx_id   = p_customer_trx_id
      AND    line_number       = p_line_number
      --AND    inventory_item_id = p_inventory_item_id
      AND    line_type         = 'LINE';
    END IF;

    logit(p_message => 'RESULT customer_trx_line_id: ' || x_invoice_line_info.customer_trx_line_id);

    exiting_sub(p_procedure_name => lc_procedure_name);

    EXCEPTION
    WHEN OTHERS
    THEN
      exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => TRUE);
      RAISE_APPLICATION_ERROR(-20101, 'PROCEDURE: ' || lc_procedure_name || ' SQLCODE: ' || SQLCODE || ' SQLERRM: ' || SQLERRM);

  END get_invoice_line_info;

  /**************************************************************
  * Helper procedure to get invoice line distribution information
  **************************************************************/

  PROCEDURE get_invoice_dist_info(p_customer_trx_line_id  IN         ra_cust_trx_line_gl_dist_all.customer_trx_line_id%TYPE,
                                  p_account_class         IN         ra_cust_trx_line_gl_dist_all.account_class%TYPE,
                                  x_invoice_dist_info     OUT NOCOPY ra_cust_trx_line_gl_dist_all%ROWTYPE)
  IS

    lc_procedure_name  CONSTANT VARCHAR2(61) := gc_package_name || '.' || 'get_invoice_dist_info';
    lt_parameters      gt_input_parameters;

  BEGIN

    lt_parameters('p_customer_trx_line_id') := p_customer_trx_line_id;
    lt_parameters('p_account_class')        := p_account_class;

    entering_sub(p_procedure_name  => lc_procedure_name,
                 p_parameters      => lt_parameters);

    SELECT *
    INTO   x_invoice_dist_info
    FROM   ra_cust_trx_line_gl_dist_all
    WHERE  customer_trx_line_id = p_customer_trx_line_id
    AND    account_class        = p_account_class
    AND    percent              = 100 -- Added for NAIT-120608
  --AND    attribute_category   = 'SALES_ACCT'; -- Commented for NAIT-120608
    ;
    logit(p_message => 'RESULT attribute6: '  || x_invoice_dist_info.attribute6);
    logit(p_message => 'RESULT attributel1: ' || x_invoice_dist_info.attribute11);

    exiting_sub(p_procedure_name => lc_procedure_name);

    EXCEPTION
    WHEN OTHERS
    THEN
      exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => TRUE);
      RAISE_APPLICATION_ERROR(-20101, 'PROCEDURE: ' || lc_procedure_name || ' SQLCODE: ' || SQLCODE || ' SQLERRM: ' || SQLERRM);

  END get_invoice_dist_info;

  /***************************************************
  * Helper procedure to get receipt method information
  ***************************************************/

  PROCEDURE get_receipt_method_info(p_receipt_method_name  IN         ar_receipt_methods.name%TYPE,
                                    x_receipt_method_id    OUT NOCOPY ar_receipt_methods.receipt_method_id%TYPE)
  IS

    lc_procedure_name  CONSTANT VARCHAR2(61) := gc_package_name || '.' || 'get_receipt_method_info';
    lt_parameters      gt_input_parameters;

  BEGIN

    lt_parameters('p_receipt_method_name') := p_receipt_method_name;

    entering_sub(p_procedure_name  => lc_procedure_name,
                 p_parameters      => lt_parameters);

    SELECT receipt_method_id
    INTO   x_receipt_method_id
    FROM   ar_receipt_methods
    WHERE  name = p_receipt_method_name;

    logit(p_message => 'RESULT receipt_method_id: ' || x_receipt_method_id);

    exiting_sub(p_procedure_name => lc_procedure_name);

    EXCEPTION
    WHEN OTHERS
    THEN
      exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => TRUE);
      RAISE_APPLICATION_ERROR(-20101, 'PROCEDURE: ' || lc_procedure_name || ' SQLCODE: ' || SQLCODE || ' SQLERRM: ' || SQLERRM);

  END get_receipt_method_info;
  
  /********************************************
  * Helper procedure to get receipt information
  ********************************************/

  PROCEDURE get_receipt_info(p_cash_receipt_id IN         ar_cash_receipts_all.cash_receipt_id%TYPE,
                             x_receipt_info    OUT NOCOPY ar_cash_receipts_all%ROWTYPE)
  IS

    lc_procedure_name  CONSTANT VARCHAR2(61) := gc_package_name || '.' || 'get_receipt_info';
    lt_parameters      gt_input_parameters;

  BEGIN

    lt_parameters('p_cash_receipt_id') := p_cash_receipt_id;

    entering_sub(p_procedure_name  => lc_procedure_name,
                 p_parameters      => lt_parameters);

    SELECT *
    INTO   x_receipt_info
    FROM   ar_cash_receipts_all
    WHERE  cash_receipt_id = p_cash_receipt_id;

    logit(p_message => 'RESULT receipt_number: ' || x_receipt_info.receipt_number);

    exiting_sub(p_procedure_name => lc_procedure_name);

    EXCEPTION
    WHEN OTHERS
    THEN
      exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => TRUE);
      RAISE_APPLICATION_ERROR(-20101, 'PROCEDURE: ' || lc_procedure_name || ' SQLCODE: ' || SQLCODE || ' SQLERRM: ' || SQLERRM);

  END get_receipt_info;

  /********************************************
  * Helper procedure to get receipt information
  ********************************************/

  PROCEDURE get_receipt_info(p_receipt_number    IN           ar_cash_receipts_all.receipt_number%TYPE,
                               p_receipt_method_id IN           ar_cash_receipts_all.receipt_method_id%TYPE,
                               x_receipt_info      OUT NOCOPY ar_cash_receipts_all%ROWTYPE)
  IS

    lc_procedure_name  CONSTANT VARCHAR2(61) := gc_package_name || '.' || 'get_receipt_info';
    lt_parameters      gt_input_parameters;

  BEGIN

    lt_parameters('p_receipt_number')    := p_receipt_number;
    lt_parameters('p_receipt_method_id') := p_receipt_method_id;

    entering_sub(p_procedure_name  => lc_procedure_name,
                 p_parameters      => lt_parameters);

    SELECT *
    INTO    x_receipt_info
    FROM    ar_cash_receipts_all
    WHERE   receipt_number = p_receipt_number
    AND     receipt_method_id = p_receipt_method_id;

    logit(p_message => 'RESULT cash_receipt_id: ' || x_receipt_info.cash_receipt_id);

    exiting_sub(p_procedure_name => lc_procedure_name);

    EXCEPTION
    WHEN OTHERS
    THEN
      exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => TRUE);
      RAISE_APPLICATION_ERROR(-20101, 'PROCEDURE: ' || lc_procedure_name || ' SQLCODE: ' || SQLCODE || ' SQLERRM: ' || SQLERRM);

  END get_receipt_info;

  /*********************************************************
  * Helper procedure to get receipt application information
  *********************************************************/

  PROCEDURE get_rec_application_info(p_customer_trx_id             IN         ar_receivable_applications_all.applied_customer_trx_id%TYPE,
                                     x_receivable_application_info OUT NOCOPY ar_receivable_applications_all%ROWTYPE)
  IS

    lc_procedure_name  CONSTANT VARCHAR2(61) := gc_package_name || '.' || 'get_rec_application_info';
    lt_parameters      gt_input_parameters;

  BEGIN

    lt_parameters('p_customer_trx_id') := p_customer_trx_id;

    entering_sub(p_procedure_name  => lc_procedure_name,
                 p_parameters      => lt_parameters);

    SELECT *
    INTO   x_receivable_application_info
    FROM   ar_receivable_applications_all
    WHERE  applied_customer_trx_id = p_customer_trx_id;

    logit(p_message => 'RESULT cash_receipt_id: ' || x_receivable_application_info.cash_receipt_id);

    exiting_sub(p_procedure_name => lc_procedure_name);

    EXCEPTION
    WHEN OTHERS
    THEN
      exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => TRUE);
      RAISE_APPLICATION_ERROR(-20101, 'PROCEDURE: ' || lc_procedure_name || ' SQLCODE: ' || SQLCODE || ' SQLERRM: ' || SQLERRM);

  END get_rec_application_info;

  /********************************************************
  * Helper procedure to get receipt application information
  ********************************************************/

  PROCEDURE get_ordt_info(p_cash_receipt_id             IN         ar_cash_receipts_all.cash_receipt_id%TYPE,
                          x_ordt_info                   OUT NOCOPY xx_ar_order_receipt_dtl%ROWTYPE)
  IS

    lc_procedure_name  CONSTANT VARCHAR2(61) := gc_package_name || '.' || 'get_ordt_info';
    lt_parameters      gt_input_parameters;

  BEGIN

    lt_parameters('p_cash_receipt_id') := p_cash_receipt_id;

    entering_sub(p_procedure_name  => lc_procedure_name,
                 p_parameters      => lt_parameters);

    SELECT *
    INTO   x_ordt_info
    FROM   xx_ar_order_receipt_dtl
    WHERE  cash_receipt_id = p_cash_receipt_id;

    logit(p_message => 'RESULT order_payment_id: ' || x_ordt_info.order_payment_id);

    exiting_sub(p_procedure_name => lc_procedure_name);

    EXCEPTION
    WHEN OTHERS
    THEN
      exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => TRUE);
      RAISE_APPLICATION_ERROR(-20101, 'PROCEDURE: ' || lc_procedure_name || ' SQLCODE: ' || SQLCODE || ' SQLERRM: ' || SQLERRM);

  END get_ordt_info;

  /*************************************************
  * Helper procedure to get order header information
  *************************************************/

  PROCEDURE get_order_header_info(p_order_number      IN         oe_order_headers_all.orig_sys_document_ref%TYPE,
                                  x_order_header_info OUT NOCOPY oe_order_headers_all%ROWTYPE)
  IS

    lc_procedure_name  CONSTANT VARCHAR2(61) := gc_package_name || '.' || 'get_order_header_info';
    lt_parameters      gt_input_parameters;

  BEGIN

    lt_parameters('p_order_number') := p_order_number;

    entering_sub(p_procedure_name  => lc_procedure_name,
                 p_parameters      => lt_parameters);

    SELECT *
    INTO   x_order_header_info
    FROM   oe_order_headers_all
    WHERE  orig_sys_document_ref  = p_order_number; --Added for NAIT-126620

    logit(p_message => 'RESULT header_id: ' || x_order_header_info.header_id);

    exiting_sub(p_procedure_name => lc_procedure_name);

    EXCEPTION
    --Begin : added for NAIT-125836-Invoice creation is failing with no_data_found trying to find the initial POS order
    WHEN NO_DATA_FOUND THEN
       BEGIN
         SELECT * 
           INTO   x_order_header_info 
           FROM   xxom_oe_order_headers_all_hist
           WHERE  orig_sys_document_ref  = p_order_number; --Added for NAIT-126620
      EXCEPTION
       WHEN OTHERS
       THEN
         exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => TRUE);
         RAISE_APPLICATION_ERROR(-20101, 'PROCEDURE: ' || lc_procedure_name || ' SQLCODE: ' || SQLCODE || ' SQLERRM: ' || SQLERRM);
      END;
        logit(p_message => 'RESULT order_number from XXAPPS_HISTORY_QUERY: ' || x_order_header_info.order_number);
        exiting_sub(p_procedure_name => lc_procedure_name); 
   --End : added for NAIT-125836-Invoice creation is failing with no_data_found trying to find the initial POS order
    WHEN OTHERS
    THEN
      exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => TRUE);
      RAISE_APPLICATION_ERROR(-20101, 'PROCEDURE: ' || lc_procedure_name || ' SQLCODE: ' || SQLCODE || ' SQLERRM: ' || SQLERRM);

  END get_order_header_info;

  /***********************************************
  * Helper procedure to get order line information
  ***********************************************/

  PROCEDURE get_order_line_info(p_header_id       IN         oe_order_lines_all.header_id%TYPE,
                                p_line_number     IN         oe_order_lines_all.line_number%TYPE,
                                x_order_line_info OUT NOCOPY oe_order_lines_all%ROWTYPE)
  IS

    lc_procedure_name  CONSTANT VARCHAR2(61) := gc_package_name || '.' || 'get_order_line_info';
    lt_parameters      gt_input_parameters;

  BEGIN

    lt_parameters('p_header_id') := p_header_id;

    entering_sub(p_procedure_name  => lc_procedure_name,
                 p_parameters      => lt_parameters);

    SELECT *
    INTO   x_order_line_info
    FROM   oe_order_lines_all
    WHERE  header_id = p_header_id
    AND    line_number = p_line_number;

    logit(p_message => 'RESULT ship_from_org_id: ' || x_order_line_info.ship_from_org_id);

    exiting_sub(p_procedure_name => lc_procedure_name);

    EXCEPTION
    --Begin : added for NAIT-125836-Invoice creation is failing with no_data_found trying to find the initial POS order     
    WHEN NO_DATA_FOUND THEN
      BEGIN
         SELECT * 
           INTO   x_order_line_info 
           FROM   xxom_oe_order_lines_all_hist
          WHERE   header_id   = p_header_id
            AND   line_number = p_line_number;
          
      EXCEPTION
       WHEN OTHERS
       THEN
         exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => TRUE);
         RAISE_APPLICATION_ERROR(-20101, 'PROCEDURE: ' || lc_procedure_name || ' SQLCODE: ' || SQLCODE || ' SQLERRM: ' || SQLERRM);
      END;

        logit(p_message => 'RESULT header_id  XXAPPS_HISTORY_QUERY: ' || x_order_line_info.header_id);
        logit(p_message => 'RESULT line_number XXAPPS_HISTORY_QUERY: ' || x_order_line_info.line_number);
        exiting_sub(p_procedure_name => lc_procedure_name);
    --End : added for NAIT-125836-Invoice creation is failing with no_data_found trying to find the initial POS order
    WHEN OTHERS
    THEN
      exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => TRUE);
      RAISE_APPLICATION_ERROR(-20101, 'PROCEDURE: ' || lc_procedure_name || ' SQLCODE: ' || SQLCODE || ' SQLERRM: ' || SQLERRM);

  END get_order_line_info;

  /************************************************************
  * Helper procedure to get order header attributes information
  ************************************************************/

  PROCEDURE get_om_hdr_attribute_info(p_header_id             IN         xx_om_header_attributes_all.header_id%TYPE,
                                      x_om_hdr_attribute_info OUT NOCOPY xx_om_header_attributes_all%ROWTYPE)
  IS

    lc_procedure_name  CONSTANT VARCHAR2(61) := gc_package_name || '.' || 'get_om_hdr_attribute_info';
    lt_parameters      gt_input_parameters;

  BEGIN

    lt_parameters('p_header_id') := p_header_id;

    entering_sub(p_procedure_name  => lc_procedure_name,
                 p_parameters      => lt_parameters);

    SELECT *
    INTO   x_om_hdr_attribute_info
    FROM   xx_om_header_attributes_all
    WHERE  header_id = p_header_id;

    logit(p_message => 'RESULT created_by_store_id: ' || x_om_hdr_attribute_info.created_by_store_id);

    exiting_sub(p_procedure_name => lc_procedure_name);

    EXCEPTION
    WHEN NO_DATA_FOUND THEN
    BEGIN
       --NAIT-125836 As we are not getting entire view from history, limiting to what ever we need
         SELECT   header_id
                 ,created_by_store_id
                 ,od_order_type
                 ,delivery_code
                 ,ship_to_state
           INTO   x_om_hdr_attribute_info.header_id
                 ,x_om_hdr_attribute_info.created_by_store_id
                 ,x_om_hdr_attribute_info.od_order_type
                 ,x_om_hdr_attribute_info.delivery_code
                 ,x_om_hdr_attribute_info.ship_to_state
         FROM   XXOM_OM_HEADER_ATTRIBUTES_HIST
         WHERE  header_id = p_header_id;
      EXCEPTION
       WHEN OTHERS
       THEN
         exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => TRUE);
         RAISE_APPLICATION_ERROR(-20101, 'PROCEDURE: ' || lc_procedure_name || ' SQLCODE: ' || SQLCODE || ' SQLERRM: ' || SQLERRM);
      END;
     WHEN OTHERS
     THEN
      exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => TRUE);
      RAISE_APPLICATION_ERROR(-20101, 'PROCEDURE: ' || lc_procedure_name || ' SQLCODE: ' || SQLCODE || ' SQLERRM: ' || SQLERRM);

  END get_om_hdr_attribute_info;
  
  /**********************************************************
  * Helper procedure to get order line attributes information
  **********************************************************/

  PROCEDURE get_om_line_attribute_info(p_line_id                IN         xx_om_line_attributes_all.line_id%TYPE,
                                       x_om_line_attribute_info OUT NOCOPY xx_om_line_attributes_all%ROWTYPE)
  IS

    lc_procedure_name  CONSTANT VARCHAR2(61) := gc_package_name || '.' || 'get_om_line_attribute_info';
    lt_parameters      gt_input_parameters;

  BEGIN

    lt_parameters('p_line_id') := p_line_id;

    entering_sub(p_procedure_name  => lc_procedure_name,
                 p_parameters      => lt_parameters);

    SELECT *
    INTO   x_om_line_attribute_info
    FROM   xx_om_line_attributes_all
    WHERE  line_id = p_line_id;

    logit(p_message => 'RESULT consignment_bank_code: ' || x_om_line_attribute_info.consignment_bank_code);

    exiting_sub(p_procedure_name => lc_procedure_name);

    EXCEPTION
    WHEN NO_DATA_FOUND THEN
     BEGIN
        --NAIT-125836 As we are not getting entire view from history, limiting to what ever we need 
        SELECT line_id, consignment_bank_code
        INTO   x_om_line_attribute_info.line_id, x_om_line_attribute_info.consignment_bank_code
        FROM   XXOM_OM_LINE_ATTRIBUTES_HIST
        WHERE  line_id = p_line_id;
      EXCEPTION
       WHEN OTHERS
       THEN
         exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => TRUE);
         RAISE_APPLICATION_ERROR(-20101, 'PROCEDURE: ' || lc_procedure_name || ' SQLCODE: ' || SQLCODE || ' SQLERRM: ' || SQLERRM);
      END;
     WHEN OTHERS
    THEN
      exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => TRUE);
      RAISE_APPLICATION_ERROR(-20101, 'PROCEDURE: ' || lc_procedure_name || ' SQLCODE: ' || SQLCODE || ' SQLERRM: ' || SQLERRM);

  END get_om_line_attribute_info;
  
  /****************************************************
  * Helper procedure to get unit of measure information
  ****************************************************/

  PROCEDURE get_tax_location_info(p_tax_state IN         xx_om_header_attributes_all.ship_to_state%TYPE,
                                  x_tax_loc   OUT NOCOPY fnd_flex_values.flex_value%TYPE)
  IS

    lc_procedure_name  CONSTANT VARCHAR2(61) := gc_package_name || '.' || 'get_tax_location_info';
    lt_parameters      gt_input_parameters;

  BEGIN

    lt_parameters('p_tax_state') := p_tax_state;

    entering_sub(p_procedure_name  => lc_procedure_name,
                 p_parameters      => lt_parameters);

    SELECT ffv.flex_value
    INTO   x_tax_loc
    FROM   fnd_flex_values ffv, fnd_flex_value_sets ffvs
    WHERE  ffv.flex_value_set_id = ffvs.flex_value_set_id
    AND    ffvs.flex_value_set_name = 'OD_GL_GLOBAL_LOCATION'
    AND    ffv.flex_value LIKE '8%'
    AND    ffv.attribute4 = p_tax_state;

    logit(p_message => 'RESULT tax location ' || x_tax_loc);

    exiting_sub(p_procedure_name => lc_procedure_name);

    EXCEPTION
    WHEN OTHERS
    THEN
      exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => TRUE);
      RAISE_APPLICATION_ERROR(-20101, 'PROCEDURE: ' || lc_procedure_name || ' SQLCODE: ' || SQLCODE || ' SQLERRM: ' || SQLERRM);

  END get_tax_location_info;
  
  /**********************************************************
  * Helper procedure to get order source id from translations
  **********************************************************/

  PROCEDURE get_order_source_id_info(p_order_name       IN         oe_order_sources.NAME%TYPE,
                                     x_order_source_id  OUT NOCOPY oe_order_sources.order_source_id%TYPE)
  IS

    lc_procedure_name  CONSTANT VARCHAR2(61) := gc_package_name || '.' || 'get_order_source_id_info';
    lt_parameters      gt_input_parameters;

  BEGIN
   
    lt_parameters('p_order_name') := p_order_name;
    
    entering_sub(p_procedure_name  => lc_procedure_name,
                 p_parameters      => lt_parameters);

    SELECT order_source_id
    INTO   x_order_source_id
    FROM   oe_order_sources 
    WHERE  NAME = p_order_name;                 

    logit(p_message => 'RESULT order_source_id ' || x_order_source_id);

    exiting_sub(p_procedure_name => lc_procedure_name);

  EXCEPTION
    WHEN OTHERS
    THEN
      exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => TRUE);
      RAISE_APPLICATION_ERROR(-20101, 'PROCEDURE: ' || lc_procedure_name || ' SQLCODE: ' || SQLCODE || ' SQLERRM: ' || SQLERRM);

  END get_order_source_id_info;
 
  /*****************************************************
  * Helper procedure to get location info for accounting
  *****************************************************/

  PROCEDURE get_location_info(p_org_id    IN         hr_all_organization_units.organization_id%TYPE,
                              x_loc_code  OUT NOCOPY hr_locations_all.location_code%TYPE,
                              x_region    OUT NOCOPY hr_locations_all.region_1%TYPE,
                              x_loc_type  OUT NOCOPY hr_lookups.meaning%TYPE)
  IS

    lc_procedure_name  CONSTANT VARCHAR2(61) := gc_package_name || '.' || 'get_location_info';
    lt_parameters      gt_input_parameters;

  BEGIN

    lt_parameters('p_org_id') := p_org_id;

    entering_sub(p_procedure_name => lc_procedure_name,
                 p_parameters     => lt_parameters);
 
    -- Order Location is not mandatory for derive accounting segments(created_by_store_id) 
    -- Shipping Location is mandatory for derive accounting segments (ship_from_org_id)
    IF p_org_id IS NOT NULL
    THEN
      SELECT SUBSTR(hla.location_code, 1, 6),
             DECODE(hla.country, 'US', hla.region_2, hla.region_1),
             hl.meaning
      INTO   x_loc_code,
             x_region,
             x_loc_type
      FROM   hr_lookups hl,
             hr_locations_all hla,
             hr_all_organization_units haou
      WHERE  haou.TYPE            = hl.lookup_code
      AND    haou.location_id     = hla.location_id
      AND    haou.organization_id = p_org_id
      AND    hl.lookup_type       = 'ORG_TYPE'
      AND    hl.enabled_flag      = 'Y';
    ELSE
      x_loc_code := NULL;
      x_region   := NULL;
      x_loc_type := NULL;
    END IF;

    logit(p_message => 'RESULT location_code: ' || x_loc_code);
    logit(p_message => 'RESULT region: '        || x_region);
    logit(p_message => 'RESULT location_type: ' || x_loc_type);

    exiting_sub(p_procedure_name => lc_procedure_name);

    EXCEPTION
    WHEN OTHERS
    THEN
      exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => TRUE);
      RAISE_APPLICATION_ERROR(-20101, 'PROCEDURE: ' || lc_procedure_name || ' SQLCODE: ' || SQLCODE || ' SQLERRM: ' || SQLERRM);

  END get_location_info;
  
  /******************************************************
  * Helper procedure to get location info for accounting
  *****************************************************/

  PROCEDURE get_new_location_info(p_store_number   IN         hr_locations_all.location_code%TYPE,
                                  x_loc_code       OUT NOCOPY hr_locations_all.location_code%TYPE,
                                  x_region         OUT NOCOPY hr_locations_all.region_1%TYPE,
                                  x_loc_type       OUT NOCOPY hr_lookups.meaning%TYPE)
  IS

    lc_procedure_name  CONSTANT VARCHAR2(61) := gc_package_name || '.' || 'get_new_location_info';
    lt_parameters      gt_input_parameters;

  BEGIN

    lt_parameters('p_store_number') := p_store_number;

    entering_sub(p_procedure_name => lc_procedure_name,
                 p_parameters     => lt_parameters);
 
    SELECT SUBSTR(hla.location_code, 1, 6),
           DECODE(hla.country, 'US', hla.region_2, hla.region_1),
           hl.meaning
    INTO   x_loc_code,
           x_region,
           x_loc_type
    FROM   hr_lookups hl,
           hr_locations_all hla,
           hr_all_organization_units haou
    WHERE  haou.TYPE            = hl.lookup_code
    AND    haou.location_id     = hla.location_id
    --AND    haou.organization_id = p_org_id
    AND    SUBSTR(hla.location_code, 1, 6) = p_store_number
    AND    hl.lookup_type       = 'ORG_TYPE'
    AND    hl.enabled_flag      = 'Y';

    logit(p_message => 'RESULT location_code: ' || x_loc_code);
    logit(p_message => 'RESULT region: '        || x_region);
    logit(p_message => 'RESULT location_type: ' || x_loc_type);

    exiting_sub(p_procedure_name => lc_procedure_name);

    EXCEPTION
    WHEN OTHERS
    THEN
      exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => TRUE);
      RAISE_APPLICATION_ERROR(-20101, 'PROCEDURE: ' || lc_procedure_name || ' SQLCODE: ' || SQLCODE || ' SQLERRM: ' || SQLERRM);

  END get_new_location_info;
  
  /***********************************************
  * Helper procedure to get segment info from CCID
  ***********************************************/

  PROCEDURE get_acct_segment_info(p_ccid_id    IN         gl_code_combinations.code_combination_id%TYPE,
                                  x_segment    OUT NOCOPY gl_code_combinations.segment4%TYPE)
  IS

    lc_procedure_name  CONSTANT VARCHAR2(61) := gc_package_name || '.' || 'get_acct_segment_info';
    lt_parameters      gt_input_parameters;

  BEGIN

    lt_parameters('p_ccid_id') := p_ccid_id;

    entering_sub(p_procedure_name => lc_procedure_name,
                 p_parameters     => lt_parameters);

    SELECT segment4
    INTO   x_segment
    FROM   gl_code_combinations
    WHERE  code_combination_id = p_ccid_id;
    
    logit(p_message => 'RESULT location - segment4: ' || x_segment);

    exiting_sub(p_procedure_name => lc_procedure_name);

    EXCEPTION
    WHEN OTHERS
    THEN
      exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => TRUE);
      RAISE_APPLICATION_ERROR(-20101, 'PROCEDURE: ' || lc_procedure_name || ' SQLCODE: ' || SQLCODE || ' SQLERRM: ' || SQLERRM);

  END get_acct_segment_info;

  /**********************************
  * Helper procedure to customer info
  **********************************/

  PROCEDURE get_customer_info(p_cust_account_id IN         hz_cust_accounts.cust_account_id%TYPE,
                              x_customer_info   OUT NOCOPY hz_cust_accounts%ROWTYPE)
  IS

    lc_procedure_name  CONSTANT VARCHAR2(61) := gc_package_name || '.' || 'get_customer_info';
    lt_parameters      gt_input_parameters;

  BEGIN

    lt_parameters('p_cust_account_id') := p_cust_account_id;

    entering_sub(p_procedure_name => lc_procedure_name,
                 p_parameters     => lt_parameters);

    SELECT  hcaa.*
    INTO    x_customer_info
    FROM    hz_cust_accounts hcaa
    WHERE   hcaa.cust_account_id = p_cust_account_id;

    logit(p_message => 'RESULT account_number: ' || x_customer_info.account_number);

    exiting_sub(p_procedure_name => lc_procedure_name);

    EXCEPTION
    WHEN OTHERS
    THEN
      exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => TRUE);
      RAISE_APPLICATION_ERROR(-20101, 'PROCEDURE: ' || lc_procedure_name || ' SQLCODE: ' || SQLCODE || ' SQLERRM: ' || SQLERRM);

  END get_customer_info;
  
  /**********************************
  * Helper procedure to customer info
  **********************************/

  PROCEDURE get_customer_pos_info(p_aops           IN         hz_cust_accounts.orig_system_reference%TYPE,
                                  x_customer_info  OUT NOCOPY hz_cust_accounts%ROWTYPE)
  IS

    lc_procedure_name  CONSTANT VARCHAR2(61) := gc_package_name || '.' || 'get_customer_pos_info';
    lt_parameters      gt_input_parameters;

  BEGIN

    lt_parameters('p_aops') := p_aops;

    entering_sub(p_procedure_name => lc_procedure_name,
                 p_parameters     => lt_parameters);

    SELECT  hcaa.*
    INTO    x_customer_info
    FROM    hz_cust_accounts hcaa
    WHERE   hcaa.orig_system_reference = p_aops||'-00001-A0';

    logit(p_message => 'RESULT account_number: ' || x_customer_info.account_number);

    exiting_sub(p_procedure_name => lc_procedure_name);

    EXCEPTION
    WHEN OTHERS
    THEN
      exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => TRUE);
      RAISE_APPLICATION_ERROR(-20101, 'PROCEDURE: ' || lc_procedure_name || ' SQLCODE: ' || SQLCODE || ' SQLERRM: ' || SQLERRM);

  END get_customer_pos_info;
  
  /**********************************
  * Helper procedure to customer info
  **********************************/

  PROCEDURE get_cust_site_pos_info(p_customer_id     IN         hz_cust_accounts.cust_account_id%TYPE,
                                   x_cust_site_info  OUT NOCOPY hz_cust_acct_sites_all%ROWTYPE)
  IS

    lc_procedure_name  CONSTANT VARCHAR2(61) := gc_package_name || '.' || 'get_cust_site_pos_info';
    lt_parameters      gt_input_parameters;

  BEGIN

    lt_parameters('p_customer_id') := p_customer_id;

    entering_sub(p_procedure_name => lc_procedure_name,
                 p_parameters     => lt_parameters);

    SELECT  hcasa.*
    INTO    x_cust_site_info
    FROM    hz_cust_acct_sites_all hcasa
    WHERE   hcasa.cust_account_id = p_customer_id
    AND     hcasa.bill_to_flag    = 'P';

    logit(p_message => 'RESULT cust_acct_site_id: ' || x_cust_site_info.cust_acct_site_id);

    exiting_sub(p_procedure_name => lc_procedure_name);

    EXCEPTION
    WHEN OTHERS
    THEN
      exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => TRUE);
      RAISE_APPLICATION_ERROR(-20101, 'PROCEDURE: ' || lc_procedure_name || ' SQLCODE: ' || SQLCODE || ' SQLERRM: ' || SQLERRM);

  END get_cust_site_pos_info;

  /**************************************************
  * Helper procedure to cust account site information
  **************************************************/

  PROCEDURE get_cust_account_site_info(p_site_use_id            IN         hz_cust_site_uses_all.site_use_id%TYPE,
                                       p_site_use_code          IN         hz_cust_site_uses_all.site_use_code%TYPE,
                                       x_cust_account_site_info OUT NOCOPY hz_cust_acct_sites_all%ROWTYPE)
  IS

    lc_procedure_name  CONSTANT VARCHAR2(61) := gc_package_name || '.' || 'get_cust_account_site_info';
    lt_parameters      gt_input_parameters;

  BEGIN

    lt_parameters('p_site_use_id')   := p_site_use_id;
    lt_parameters('p_site_use_code') := p_site_use_code;

    entering_sub(p_procedure_name => lc_procedure_name,
                 p_parameters     => lt_parameters);

    SELECT  hcasa.*
    INTO    x_cust_account_site_info
    FROM    hz_cust_accounts       hca,
            hz_cust_acct_sites_all hcasa,
            hz_cust_site_uses_all  hcsua
    WHERE   hca.cust_account_id     = hcasa.cust_account_id
    AND     hcasa.status            = 'A'
    AND     hcsua.cust_acct_site_id = hcasa.cust_acct_site_id
    AND     hcsua.site_use_id       = p_site_use_id
    AND     hcsua.site_use_code     = p_site_use_code
    AND     hcsua.status            = 'A';

    logit(p_message => 'RESULT cust_acct_site_id: ' || x_cust_account_site_info.cust_acct_site_id);

    exiting_sub(p_procedure_name => lc_procedure_name);

    EXCEPTION
    WHEN OTHERS
    THEN
      exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => TRUE);
      RAISE_APPLICATION_ERROR(-20101, 'PROCEDURE: ' || lc_procedure_name || ' SQLCODE: ' || SQLCODE || ' SQLERRM: ' || SQLERRM);

  END get_cust_account_site_info;

  /**********************************************
  * Helper procedure to cust location information
  **********************************************/

  PROCEDURE get_cust_location_info(p_cust_acct_site_id  IN         hz_cust_acct_sites_all.cust_acct_site_id%TYPE,
                                   x_cust_location_info OUT NOCOPY hz_locations%ROWTYPE)
  IS

    lc_procedure_name  CONSTANT VARCHAR2(61) := gc_package_name || '.' || 'get_cust_location_info';
    lt_parameters      gt_input_parameters;

  BEGIN

    lt_parameters('p_cust_acct_site_id') := p_cust_acct_site_id;

    entering_sub(p_procedure_name => lc_procedure_name,
                 p_parameters     => lt_parameters);

    SELECT  hl.*
    INTO    x_cust_location_info
    FROM    hz_cust_acct_sites_all hcasa,
            hz_party_sites         hps,
            hz_locations           hl
    WHERE   hcasa.cust_acct_site_id  = p_cust_acct_site_id
    AND     hps.party_site_id        = hcasa.party_site_id
    AND     hl.location_id           = hps.location_id;

    logit(p_message => 'RESULT location_id: ' || x_cust_location_info.location_id);

    exiting_sub(p_procedure_name => lc_procedure_name);

    EXCEPTION
    WHEN OTHERS
    THEN
      exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => TRUE);
      RAISE_APPLICATION_ERROR(-20101, 'PROCEDURE: ' || lc_procedure_name || ' SQLCODE: ' || SQLCODE || ' SQLERRM: ' || SQLERRM);

  END get_cust_location_info;

  /******************************************
  * Helper procedure to get customer site osr
  ******************************************/

  PROCEDURE get_cust_site_osr_info(p_owner_table_name   IN         hz_orig_sys_references.owner_table_name%TYPE,
                                   p_orig_system        IN         hz_orig_sys_references.orig_system%TYPE,
                                   p_status             IN         hz_orig_sys_references.status%TYPE,
                                   p_owner_table_id     IN         hz_orig_sys_references.owner_table_id%TYPE,
                                   x_cust_site_osr_info OUT NOCOPY hz_orig_sys_references%ROWTYPE)
  IS

    lc_procedure_name  CONSTANT VARCHAR2(61) := gc_package_name || '.' || 'get_cust_site_osr_info';
    lt_parameters      gt_input_parameters;

  BEGIN

    lt_parameters('p_owner_table_name') := p_owner_table_name;
    lt_parameters('p_orig_system')      := p_orig_system;
    lt_parameters('p_status')           := p_status;
    lt_parameters('p_owner_table_id')   := p_owner_table_id;

    entering_sub(p_procedure_name => lc_procedure_name,
                 p_parameters     => lt_parameters);

    SELECT  *
    INTO    x_cust_site_osr_info
    FROM    hz_orig_sys_references
    WHERE   owner_table_name = p_owner_table_name
    AND     orig_system      = p_orig_system
    AND     status           = p_status
    AND     owner_table_id   = p_owner_table_id;

    logit(p_message => 'RESULT orig_system_reference: ' || x_cust_site_osr_info.orig_system_reference);

    exiting_sub(p_procedure_name => lc_procedure_name);

    EXCEPTION
    WHEN OTHERS
    THEN
      exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => TRUE);
      RAISE_APPLICATION_ERROR(-20101, 'PROCEDURE: ' || lc_procedure_name || ' SQLCODE: ' || SQLCODE || ' SQLERRM: ' || SQLERRM);

  END get_cust_site_osr_info;
  
  /***************************************************
  * Helper function to get BSD customer Profile info
  ****************************************************/

  FUNCTION get_cust_profile_info(p_aops_customer_id   IN   hz_cust_accounts.orig_system_reference%TYPE)
  RETURN VARCHAR2
  AS

    lc_procedure_name  CONSTANT VARCHAR2(61) := gc_package_name || '.' || 'get_cust_profile_info';
    lt_parameters      gt_input_parameters;
    l_customer_Type    VARCHAR2(1):=NULL;
    l_cust_profile_id  NUMBER;

  BEGIN

    lt_parameters('p_aops_customer_id') := p_aops_customer_id;

    entering_sub(p_procedure_name => lc_procedure_name,
                 p_parameters     => lt_parameters);

    SELECT hcp.cust_account_profile_id 
      INTO l_cust_profile_id
      FROM hz_customer_profiles       hcp
      ,    hz_cust_accounts           hcaa
     WHERE 1                          =1
       AND hcp.cust_account_id        =hcaa.cust_account_id
       AND hcp.attribute3             ='Y'
       AND hcp.site_use_id            IS NULL
       AND hcaa.orig_system_reference =p_aops_customer_id||'-00001-A0';

        logit(p_message => 'RESULT cust_account_profile_id: ' || l_cust_profile_id);

        IF l_cust_profile_id IS NOT NULL
         THEN 
            l_customer_Type:='C'; 
         ELSE 
            l_customer_Type:='R';
         END IF;

        RETURN l_customer_Type;

    EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
              l_customer_Type:='R';
       RETURN l_customer_Type;
              logit(p_message => 'RESULT l_customer_Type: ' || l_customer_Type);
    WHEN OTHERS
    THEN
      exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => TRUE);
      RAISE_APPLICATION_ERROR(-20101, 'PROCEDURE: ' || lc_procedure_name || ' SQLCODE: ' || SQLCODE || ' SQLERRM: ' || SQLERRM);

  END get_cust_profile_info;

  /***************************************
  * Helper procedure to get plcc card code
  ***************************************/

  PROCEDURE get_plcc_card_code(p_card_bin_number IN         xx_ar_order_receipt_dtl.credit_card_number%TYPE,
                               x_card_code       OUT NOCOPY xx_ar_order_receipt_dtl.credit_card_code%TYPE)
  IS

    lc_procedure_name  CONSTANT VARCHAR2(61) := gc_package_name || '.' || 'get_plcc_card_code';
    lt_parameters      gt_input_parameters;

    lc_action           VARCHAR2(1000);

    lt_translation_info xx_fin_translatevalues%ROWTYPE;

  BEGIN

    lt_parameters('p_card_bin_number') := p_card_bin_number;

    entering_sub(p_procedure_name => lc_procedure_name,
                 p_parameters     => lt_parameters);

    BEGIN

      /***************************************
      * Check translation table with card bin.
      ***************************************/

      lc_action :=  'Calling get_translation_info with card bin number';

      lt_translation_info := NULL;

      lt_translation_info.source_value1 := p_card_bin_number;

      get_translation_info(p_translation_name  => 'XX_AR_SUBSCRIPTIONS',
                           px_translation_info => lt_translation_info);

      x_card_code := lt_translation_info.target_value1;
    EXCEPTION
    WHEN NO_DATA_FOUND
    THEN
      x_card_code := NULL;
    WHEN OTHERS
    THEN
      x_card_code := NULL;
    END;

    IF (x_card_code IS NULL)
    THEN
      /**********************************************
      * Check translation table for default card type
      **********************************************/

      lc_action :=  'Calling get_translation_info for default card type';

      lt_translation_info := NULL;

      lt_translation_info.source_value1 := 'DEFAULT';

      get_translation_info(p_translation_name  => 'XX_AR_SUBSCRIPTIONS',
                           px_translation_info => lt_translation_info);

      x_card_code := lt_translation_info.target_value1;
    END IF;

    logit(p_message => 'RESULT card_type_name: ' || x_card_code);

    exiting_sub(p_procedure_name => lc_procedure_name);

    EXCEPTION
    WHEN OTHERS
    THEN
      exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => TRUE);
      RAISE_APPLICATION_ERROR(-20101, 'PROCEDURE: ' || lc_procedure_name || ' SQLCODE: ' || SQLCODE || ' SQLERRM: ' || SQLERRM);

  END get_plcc_card_code;

  /* ***********************************************************************************
  * Get all the subscription records associated with a contract/billing sequence number
  ************************************************************************************/

  PROCEDURE get_subscription_array(p_contract_id             IN         xx_ar_subscriptions.contract_id%TYPE,
                                   p_billing_sequence_number IN         xx_ar_subscriptions.billing_sequence_number%TYPE,
                                   x_subscription_array      OUT NOCOPY subscription_table)
  IS
    lc_procedure_name  CONSTANT VARCHAR2(61) := gc_package_name || '.' || 'get_subscription_array';
    lt_parameters      gt_input_parameters;
  BEGIN

    lt_parameters('p_contract_id')             := p_contract_id;
    lt_parameters('p_billing_sequence_number') := p_billing_sequence_number;

    entering_sub(p_procedure_name  => lc_procedure_name,
                 p_parameters      => lt_parameters);

    SELECT * BULK COLLECT
    INTO   x_subscription_array
    FROM   xx_ar_subscriptions
    WHERE  contract_id             = p_contract_id
    AND    billing_sequence_number = p_billing_sequence_number;

    logit(p_message => 'RESULT subscription array count: ' || x_subscription_array.COUNT);

    exiting_sub(p_procedure_name => lc_procedure_name);

    EXCEPTION
    WHEN OTHERS
    THEN
      exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => TRUE);
      RAISE_APPLICATION_ERROR(-20101, 'PROCEDURE: ' || lc_procedure_name || ' SQLCODE: ' || SQLCODE || ' SQLERRM: ' || SQLERRM);

  END get_subscription_array;
  
  /* *************************************************************************************************
  * Get all the subscription records associated with a contract/billing sequence number for Alternate
  ***************************************************************************************************/

  PROCEDURE get_alt_subscription_array(p_contract_id             IN         xx_ar_subscriptions.contract_id%TYPE,
                                       p_billing_sequence_number IN         xx_ar_subscriptions.billing_sequence_number%TYPE,
                                       p_line_number IN                     xx_ar_subscriptions.contract_line_number%TYPE,
                                       x_subscription_array      OUT NOCOPY subscription_table)
  IS
    lc_procedure_name  CONSTANT VARCHAR2(61) := gc_package_name || '.' || 'get_alt_subscription_array';
    lt_parameters      gt_input_parameters;
  BEGIN

    lt_parameters('p_contract_id')             := p_contract_id;
    lt_parameters('p_billing_sequence_number') := p_billing_sequence_number;

    entering_sub(p_procedure_name  => lc_procedure_name,
                 p_parameters      => lt_parameters);

    SELECT * BULK COLLECT
    INTO   x_subscription_array
    FROM   xx_ar_subscriptions
    WHERE  contract_id             = p_contract_id
    AND    contract_line_number    = p_line_number
    AND    billing_sequence_number = p_billing_sequence_number;

    logit(p_message => 'RESULT subscription array count: ' || x_subscription_array.COUNT);

    exiting_sub(p_procedure_name => lc_procedure_name);

    EXCEPTION
    WHEN OTHERS
    THEN
      exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => TRUE);
      RAISE_APPLICATION_ERROR(-20101, 'PROCEDURE: ' || lc_procedure_name || ' SQLCODE: ' || SQLCODE || ' SQLERRM: ' || SQLERRM);

  END get_alt_subscription_array;
  
  
  
  /*********************************************
  * Helper procedure to update contract line info
  *********************************************/
  
  PROCEDURE update_line_info(p_contract_line_info IN  xx_ar_contract_lines%ROWTYPE)
  IS
    PRAGMA AUTONOMOUS_TRANSACTION;

    lc_procedure_name  CONSTANT VARCHAR2(61) := gc_package_name || '.' || 'update_line_info';
    lt_parameters      gt_input_parameters;

  BEGIN

    lt_parameters('p_contract_line_info.renewal_type')           :=  p_contract_line_info.renewal_type;
    lt_parameters('p_contract_line_info.last_updated_by')        :=  p_contract_line_info.last_updated_by;
    lt_parameters('p_contract_line_info.last_update_date')       :=  p_contract_line_info.last_update_date;
    lt_parameters('p_contract_line_info.attribute1')             :=  p_contract_line_info.attribute1;
    lt_parameters('p_contract_line_info.attribute2')             :=  p_contract_line_info.attribute2;
    lt_parameters('p_contract_line_info.attribute3')             :=  p_contract_line_info.attribute3;
   -- lt_parameters('p_contract_line_info.contract_line_number')   :=  p_subscription_payload_info.contract_line_number;
   -- lt_parameters('p_contract_line_info.source')                 :=  p_subscription_payload_info.source;

    entering_sub(p_procedure_name  => lc_procedure_name,
                 p_parameters      => lt_parameters);

    UPDATE xx_ar_contract_lines 
       SET renewal_type           =  p_contract_line_info.renewal_type,
           last_updated_by        =  p_contract_line_info.last_updated_by,
           last_update_date       =  p_contract_line_info.last_update_date,
           attribute1             =  p_contract_line_info.attribute1,
           attribute2             =  p_contract_line_info.attribute2,
           attribute3             =  p_contract_line_info.attribute3
      WHERE 1                     =  1
        AND contract_id           =  p_contract_line_info.contract_id
      --AND contract_line_id      =  p_contract_line_info.contract_line_id
        AND contract_line_number  =  p_contract_line_info.contract_line_number;
    COMMIT;

    exiting_sub(p_procedure_name => lc_procedure_name);

    EXCEPTION
    WHEN OTHERS
    THEN
      exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => TRUE);
      RAISE_APPLICATION_ERROR(-20101, 'PROCEDURE: ' || lc_procedure_name || ' SQLCODE: ' || SQLCODE || ' SQLERRM: ' || SQLERRM);

  END update_line_info;
  

  /*********************************************
  * Helper procedure to update subscription info
  *********************************************/

  PROCEDURE update_subscription_info(px_subscription_info  IN OUT NOCOPY xx_ar_subscriptions%ROWTYPE)
  IS
    PRAGMA AUTONOMOUS_TRANSACTION;

    lc_procedure_name  CONSTANT VARCHAR2(61) := gc_package_name || '.' || 'update_subscription_info';
    lt_parameters      gt_input_parameters;

  BEGIN

    lt_parameters('p_contract_id')             := px_subscription_info.contract_id;
    lt_parameters('p_contract_line_number')    := px_subscription_info.contract_line_number;
    lt_parameters('p_billing_sequence_number') := px_subscription_info.billing_sequence_number;

    entering_sub(p_procedure_name  => lc_procedure_name,
                 p_parameters      => lt_parameters);

    px_subscription_info.last_update_date := SYSDATE;
    px_subscription_info.last_updated_by  := NVL(FND_GLOBAL.user_id, -1);

    UPDATE xx_ar_subscriptions
    SET    ROW = px_subscription_info
    WHERE  contract_id             = px_subscription_info.contract_id
    AND    contract_line_number    = px_subscription_info.contract_line_number
    AND    billing_sequence_number = px_subscription_info.billing_sequence_number;

    logit(p_message => 'RESULT records update: ' || SQL%ROWCOUNT);

    COMMIT;

    exiting_sub(p_procedure_name => lc_procedure_name);

    EXCEPTION
    WHEN OTHERS
    THEN
      exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => TRUE);
      RAISE_APPLICATION_ERROR(-20101, 'PROCEDURE: ' || lc_procedure_name || ' SQLCODE: ' || SQLCODE || ' SQLERRM: ' || SQLERRM);

  END update_subscription_info;

  /*********************************************
  * Helper procedure to update subscription info
  *********************************************/

  PROCEDURE update_contracts_info(p_contract_id           IN xx_ar_contracts.contract_id%TYPE
                                 ,p_cc_trans_id           IN xx_ar_contracts.cc_trans_id%TYPE
                                 ,p_cc_trans_id_source    IN xx_ar_contracts.cc_trans_id_source%TYPE
                                 ,p_cof_trans_id_scm_flag IN xx_ar_contracts.cof_trans_id_scm_flag%TYPE)
  IS
    PRAGMA AUTONOMOUS_TRANSACTION;

    lc_procedure_name  CONSTANT VARCHAR2(61) := gc_package_name || '.' || 'update_contracts_info';
    lt_parameters      gt_input_parameters;

  BEGIN

    lt_parameters('p_contract_id')           := p_contract_id;
    lt_parameters('p_cc_trans_id')           := p_cc_trans_id;
    lt_parameters('p_cc_trans_id_source')    := p_cc_trans_id_source;
    lt_parameters('p_cof_trans_id_scm_flag') := p_cof_trans_id_scm_flag;

    entering_sub(p_procedure_name  => lc_procedure_name,
                 p_parameters      => lt_parameters);

    UPDATE xx_ar_contracts
    SET    cc_trans_id           = p_cc_trans_id
          ,cc_trans_id_source    = p_cc_trans_id_source
          ,cof_trans_id_scm_flag = p_cof_trans_id_scm_flag
          ,last_update_date      = SYSDATE
          ,last_updated_by       = NVL(FND_GLOBAL.user_id, -1)
    WHERE  contract_id           = p_contract_id;

    logit(p_message => 'RESULT records update: ' || SQL%ROWCOUNT);

    COMMIT;

    exiting_sub(p_procedure_name => lc_procedure_name);

    EXCEPTION
    WHEN OTHERS
    THEN
      exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => TRUE);
      RAISE_APPLICATION_ERROR(-20101, 'PROCEDURE: ' || lc_procedure_name || ' SQLCODE: ' || SQLCODE || ' SQLERRM: ' || SQLERRM);

  END update_contracts_info;

  /****************************************************
  * Helper procedure to insert subscription errors info
  ****************************************************/

  PROCEDURE insert_subscription_error_info(p_subscription_error_info  IN  xx_ar_subscriptions_error%ROWTYPE)
  IS
    PRAGMA AUTONOMOUS_TRANSACTION;

    lc_procedure_name  CONSTANT VARCHAR2(61) := gc_package_name || '.' || 'insert_subscription_error_info';
    lt_parameters      gt_input_parameters;

  BEGIN

    lt_parameters('p_subscription_error_info.contract_id')             :=  p_subscription_error_info.contract_id;
    lt_parameters('p_subscription_error_info.contract_number')         :=  p_subscription_error_info.contract_number;
    lt_parameters('p_subscription_error_info.contract_line_number')    :=  p_subscription_error_info.contract_line_number;
    lt_parameters('p_subscription_error_info.billing_sequence_number') :=  p_subscription_error_info.billing_sequence_number;
    lt_parameters('p_subscription_error_info.error_module')            :=  p_subscription_error_info.error_module;
    lt_parameters('p_subscription_error_info.error_message')           :=  p_subscription_error_info.error_message;

    entering_sub(p_procedure_name  => lc_procedure_name, p_parameters      => lt_parameters);

    INSERT INTO xx_ar_subscriptions_error
    VALUES p_subscription_error_info;

    logit(p_message => 'RESULT records inserted: ' || SQL%ROWCOUNT);

    COMMIT;

    exiting_sub(p_procedure_name => lc_procedure_name);

    EXCEPTION
    WHEN OTHERS
    THEN
      exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => TRUE);
      RAISE_APPLICATION_ERROR(-20101, 'PROCEDURE: ' || lc_procedure_name || ' SQLCODE: ' || SQLCODE || ' SQLERRM: ' || SQLERRM);

  END insert_subscription_error_info;

  /***************************************************
  * Helper procedure to insert subscription gt info
  ***************************************************/

  PROCEDURE insert_subscript_payload_info(p_subscription_payload_info  IN  xx_ar_subscription_payloads%ROWTYPE)
  IS
    PRAGMA AUTONOMOUS_TRANSACTION;

    lc_procedure_name  CONSTANT VARCHAR2(61) := gc_package_name || '.' || 'insert_subscript_payload_info';
    lt_parameters      gt_input_parameters;

  BEGIN

    lt_parameters('p_subscription_payload_info.payload_id')             :=  p_subscription_payload_info.payload_id;
    lt_parameters('p_subscription_payload_info.response_data')          :=  p_subscription_payload_info.response_data;
    lt_parameters('p_subscription_payload_info.creation_date')          :=  p_subscription_payload_info.creation_date;
    lt_parameters('p_subscription_payload_info.created_by')             :=  p_subscription_payload_info.created_by;
    lt_parameters('p_subscription_payload_info.last_updated_by')        :=  p_subscription_payload_info.last_updated_by;
    lt_parameters('p_subscription_payload_info.last_update_date')       :=  p_subscription_payload_info.last_update_date;
    lt_parameters('p_subscription_payload_info.input_payload')          :=  p_subscription_payload_info.input_payload;
    lt_parameters('p_subscription_payload_info.contract_number')        :=  p_subscription_payload_info.contract_number;
    lt_parameters('p_subscription_payload_info.billing_sequence_number'):=  p_subscription_payload_info.billing_sequence_number;
    lt_parameters('p_subscription_payload_info.contract_line_number')   :=  p_subscription_payload_info.contract_line_number;
    lt_parameters('p_subscription_payload_info.source')                 :=  p_subscription_payload_info.source;

    entering_sub(p_procedure_name  => lc_procedure_name,
                 p_parameters      => lt_parameters);

    INSERT INTO xx_ar_subscription_payloads
    VALUES p_subscription_payload_info;


    logit(p_message => 'RESULT records inserted: ' || SQL%ROWCOUNT);

    COMMIT;

    exiting_sub(p_procedure_name => lc_procedure_name);

    EXCEPTION
    WHEN OTHERS
    THEN
      exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => TRUE);
      RAISE_APPLICATION_ERROR(-20101, 'PROCEDURE: ' || lc_procedure_name || ' SQLCODE: ' || SQLCODE || ' SQLERRM: ' || SQLERRM);

  END insert_subscript_payload_info;

  /*******************************************************
  * Helper procedure to retrieve auth response information
  *******************************************************/

  PROCEDURE retrieve_auth_response_info(p_payload_id  IN                      xx_ar_subscription_payloads.payload_id%TYPE,
                                        px_ar_subscription_info IN OUT NOCOPY xx_ar_subscriptions%ROWTYPE)
  IS

    lc_procedure_name  CONSTANT VARCHAR2(61) := gc_package_name || '.' || 'retrieve_auth_response_info';
    lt_parameters      gt_input_parameters;

    lc_action          VARCHAR2(1000);

  BEGIN

    lt_parameters('p_payload_id') := p_payload_id;

    entering_sub(p_procedure_name  => lc_procedure_name,
                 p_parameters      => lt_parameters);

    lc_action := 'Get response auth_status';

    SELECT jt0.transactionid,
           jt0.transactiondatetime,
           jt1.transaction_code,
           jt1.transaction_message,
           jt2.auth_status,
           jt2.auth_message,
           jt2.avs_code,
           jt2.auth_code,
           jt2.cof_trans_id
    INTO   px_ar_subscription_info.auth_transactionid,
           px_ar_subscription_info.auth_datetime,
           px_ar_subscription_info.authorization_code,
           px_ar_subscription_info.auth_transaction_message,
           px_ar_subscription_info.auth_status,
           px_ar_subscription_info.auth_message,
           px_ar_subscription_info.auth_avs_code,
           px_ar_subscription_info.auth_code,
           px_ar_subscription_info.cof_trans_id
    FROM   xx_ar_subscription_payloads auth_response,
           JSON_TABLE ( auth_response.response_data, '$.paymentAuthorizationResponse.transactionHeader' COLUMNS ( "TRANSACTIONID"    VARCHAR2(60) PATH '$.consumerTransactionId' ,"TRANSACTIONDATETIME" VARCHAR2(30) PATH '$.consumerTransactionDateTime' )) "JT0" ,
           JSON_TABLE ( auth_response.response_data, '$.paymentAuthorizationResponse.transactionStatus' COLUMNS ( "TRANSACTION_CODE" VARCHAR2(60) PATH '$.code' ,"TRANSACTION_MESSAGE" VARCHAR2(256) PATH '$.message' )) "JT1" ,
           JSON_TABLE ( auth_response.response_data, '$.paymentAuthorizationResponse.authorizationResult' COLUMNS ( "AUTH_STATUS"    VARCHAR2(60) PATH '$.code' ,"AUTH_MESSAGE" VARCHAR2(256) PATH '$.message' ,"AVS_CODE" VARCHAR2(60) PATH '$.avsCode' ,"AUTH_CODE" VARCHAR2(60) PATH '$.authCode',"COF_TRANS_ID" VARCHAR2(256) PATH '$.cofTransactionId'  )) "JT2"
    WHERE  auth_response.payload_id = p_payload_id;

    exiting_sub(p_procedure_name => lc_procedure_name);

    EXCEPTION
    WHEN NO_DATA_FOUND 
    THEN
      
      BEGIN
        lc_action := 'Get response auth_status';
      
        SELECT jt0.transactionid,
               jt0.transactiondatetime,
               SUBSTR(jt1.transaction_code,1,15),
               jt1.transaction_message
        INTO   px_ar_subscription_info.auth_transactionid,
               px_ar_subscription_info.auth_datetime,
               px_ar_subscription_info.authorization_code,
               px_ar_subscription_info.auth_transaction_message
        FROM   xx_ar_subscription_payloads auth_response,
               JSON_TABLE ( auth_response.response_data, '$.paymentAuthorizationResponse.transactionHeader' COLUMNS ( "TRANSACTIONID"    VARCHAR2(60) PATH '$.consumerTransactionId' ,"TRANSACTIONDATETIME" VARCHAR2(30) PATH '$.consumerTransactionDateTime' )) "JT0" ,
               JSON_TABLE ( auth_response.response_data, '$.paymentAuthorizationResponse.transactionStatus' COLUMNS ( "TRANSACTION_CODE" VARCHAR2(60) PATH '$.code' ,"TRANSACTION_MESSAGE" VARCHAR2(256) PATH '$.message' )) "JT1" 
        WHERE  auth_response.payload_id = p_payload_id;
      
        exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => TRUE);
      
      EXCEPTION
      WHEN OTHERS
      THEN
        exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => TRUE);
        RAISE_APPLICATION_ERROR(-20101, 'PROCEDURE: ' || lc_procedure_name || ' SQLCODE: ' || SQLCODE || ' SQLERRM: ' || SQLERRM);
      END;

    WHEN OTHERS
    THEN
      exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => TRUE);
      RAISE_APPLICATION_ERROR(-20101, 'PROCEDURE: ' || lc_procedure_name || ' SQLCODE: ' || SQLCODE || ' SQLERRM: ' || SQLERRM);

  END retrieve_auth_response_info;

  /*********************************************************
  * Helper procedure to insert ra_interface_lines_all table.
  *********************************************************/

  PROCEDURE insert_ra_interface_lines_all(p_ra_interface_lines_all_info  IN  ra_interface_lines_all%ROWTYPE)
  IS

    lc_procedure_name  CONSTANT VARCHAR2(61) := gc_package_name || '.' || 'insert_ra_interface_lines_all';
    lt_parameters      gt_input_parameters;

  BEGIN

    lt_parameters('p_ra_interface_lines_all_info.trx_number')        :=  p_ra_interface_lines_all_info.trx_number;
    lt_parameters('p_ra_interface_lines_all_info.interface_line_id') :=  p_ra_interface_lines_all_info.interface_line_id;

    entering_sub(p_procedure_name  => lc_procedure_name,
                 p_parameters      => lt_parameters);

    INSERT INTO ra_interface_lines_all
    VALUES p_ra_interface_lines_all_info;

    logit(p_message => 'RESULT records inserted: ' || SQL%ROWCOUNT);

    exiting_sub(p_procedure_name => lc_procedure_name);

    EXCEPTION
    WHEN OTHERS
    THEN
      exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => TRUE);
      RAISE_APPLICATION_ERROR(-20101, 'PROCEDURE: ' || lc_procedure_name || ' SQLCODE: ' || SQLCODE || ' SQLERRM: ' || SQLERRM);

  END insert_ra_interface_lines_all;

  /*****************************************************************
  * Helper procedure to insert ra_interface_distributions_all table.
  *****************************************************************/

  PROCEDURE insert_ra_interface_dists_all(p_ra_interface_dists_all_info  IN  ra_interface_distributions_all%ROWTYPE)
  IS

    lc_procedure_name  CONSTANT VARCHAR2(61) := gc_package_name || '.' || 'insert_ra_interface_dists_all';
    lt_parameters      gt_input_parameters;

  BEGIN

    lt_parameters('p_ra_interface_dists_all_info.interface_line_id') :=  p_ra_interface_dists_all_info.interface_line_id;

    entering_sub(p_procedure_name  => lc_procedure_name,
                 p_parameters      => lt_parameters);

    INSERT INTO ra_interface_distributions_all
    VALUES p_ra_interface_dists_all_info;

    logit(p_message => 'RESULT records inserted: ' || SQL%ROWCOUNT);

    exiting_sub(p_procedure_name => lc_procedure_name);

    EXCEPTION
    WHEN OTHERS
    THEN
      exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => TRUE);
      RAISE_APPLICATION_ERROR(-20101, 'PROCEDURE: ' || lc_procedure_name || ' SQLCODE: ' || SQLCODE || ' SQLERRM: ' || SQLERRM);

  END insert_ra_interface_dists_all;

  /*********************************************************
  * Helper procedure to insert xx_ar_order_receipt_dtl table
  *********************************************************/

  PROCEDURE insert_ordt_info(p_ordt_info  IN  xx_ar_order_receipt_dtl%ROWTYPE)
  IS

    lc_procedure_name  CONSTANT VARCHAR2(61) := gc_package_name || '.' || 'insert_ordt_info';
    lt_parameters      gt_input_parameters;

  BEGIN

    lt_parameters('p_ordt_info.order_payment_id') :=  p_ordt_info.order_payment_id;

    entering_sub(p_procedure_name  => lc_procedure_name,
                 p_parameters      => lt_parameters);

    INSERT INTO xx_ar_order_receipt_dtl
    VALUES p_ordt_info;

    logit(p_message => 'RESULT records inserted: ' || SQL%ROWCOUNT);

    exiting_sub(p_procedure_name => lc_procedure_name);

    EXCEPTION
    WHEN OTHERS
    THEN
      exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => TRUE);
      RAISE_APPLICATION_ERROR(-20101, 'PROCEDURE: ' || lc_procedure_name || ' SQLCODE: ' || SQLCODE || ' SQLERRM: ' || SQLERRM);

  END insert_ordt_info;

  /*******************************************
  * Helper procedure to get item cost from RMS
  *******************************************/

  PROCEDURE process_item_cost(p_rms_db_link         IN            VARCHAR2,
                              px_subscription_array IN OUT NOCOPY subscription_table,
                              px_item_cost_tab      IN OUT NOCOPY item_cost_tab)
  IS

    lc_procedure_name  CONSTANT VARCHAR2(61) := gc_package_name || '.' || 'process_item_cost';
    lt_parameters      gt_input_parameters;

    lc_action             VARCHAR2(1000);
    lc_query              VARCHAR2(1000);

    lr_contract_line_info      xx_ar_contract_lines%ROWTYPE;
    lr_subscription_error_info xx_ar_subscriptions_error%ROWTYPE;

    le_processing              EXCEPTION;

    lc_error                   VARCHAR2(1000);
    
    lt_translation_info        xx_fin_translatevalues%ROWTYPE;

    lc_termination_sku         xx_fin_translatevalues.target_value1%TYPE;

  BEGIN

    entering_sub(p_procedure_name  => lc_procedure_name,
                 p_parameters      => lt_parameters);

    lc_action := 'Looping thru subscription array';


    FOR indx IN 1 .. px_subscription_array.COUNT
    LOOP

      BEGIN
        IF px_subscription_array(indx).item_unit_cost IS NULL
        THEN

          lc_action := 'Calling get_contract_line_info at process_item_cost';

          get_contract_line_info(p_contract_id          => px_subscription_array(indx).contract_id,
                                 p_contract_line_number => px_subscription_array(indx).contract_line_number,
                                 x_contract_line_info   => lr_contract_line_info);

          /********************
          * Get termination SKU
          ********************/
          
          lc_action :=  'Calling get_translation_info for termination SKU';
          
          lt_translation_info := NULL;
          
          lt_translation_info.source_value1 := 'TERMINATION_SKU';
          
          get_translation_info(p_translation_name  => 'XX_AR_SUBSCRIPTIONS',
                               px_translation_info => lt_translation_info);
          
          lc_termination_sku  := lt_translation_info.target_value1;

          IF lr_contract_line_info.item_name != lc_termination_sku
          THEN
            IF (px_item_cost_tab.EXISTS(lr_contract_line_info.item_name) = FALSE)
            THEN
              lc_action := 'Select item cost from RMS item: ' || lr_contract_line_info.item_name;
            
              logit(p_message => lc_action);
            
              lc_query := 'SELECT cost FROM XX_RMS_MV_SSB ' || ' WHERE item = '|| lr_contract_line_info.item_name;
            
           
              EXECUTE IMMEDIATE lc_query INTO px_item_cost_tab(lr_contract_line_info.item_name);

              px_subscription_array(indx).item_unit_cost := px_item_cost_tab(lr_contract_line_info.item_name);
            
            ELSE
            
              lc_action := 'Existing item cost from RMS item: ' || lr_contract_line_info.item_name;
            
              logit(p_message => lc_action);
            
              px_subscription_array(indx).item_unit_cost := px_item_cost_tab(lr_contract_line_info.item_name);
            
            END IF;
          ELSE
            px_subscription_array(indx).item_unit_cost := 0;
          END IF;

          lc_action := 'Calling update_subscription_info';

          update_subscription_info(px_subscription_info => px_subscription_array(indx));

        END IF;

      EXCEPTION
        WHEN OTHERS
        THEN

          lr_subscription_error_info.contract_id             := px_subscription_array(indx).contract_id;
          lr_subscription_error_info.contract_number         := px_subscription_array(indx).contract_number;
          lr_subscription_error_info.contract_line_number    := px_subscription_array(indx).contract_line_number;
          lr_subscription_error_info.billing_sequence_number := px_subscription_array(indx).billing_sequence_number;
          lr_subscription_error_info.error_module            := lc_procedure_name;
          lr_subscription_error_info.error_message           := SUBSTR('Action: ' || lc_action || ' Error: ' || SQLCODE || ' ' || SQLERRM, 1, gc_max_err_size);
          lr_subscription_error_info.creation_date           := SYSDATE;

          lc_action := 'Calling insert_subscription_error_info';

          insert_subscription_error_info(p_subscription_error_info => lr_subscription_error_info);

          lc_error := lr_subscription_error_info.error_message;

          RAISE le_processing;
      END;
    END LOOP;

    exiting_sub(p_procedure_name => lc_procedure_name);

  EXCEPTION
  WHEN le_processing
  THEN
    exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => TRUE);
    RAISE_APPLICATION_ERROR(-20101, 'PROCEDURE: ' || lc_procedure_name || ' ERROR: ' || lc_error);
  WHEN OTHERS
  THEN
    exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => TRUE);
    RAISE_APPLICATION_ERROR(-20101, 'PROCEDURE: ' || lc_procedure_name || ' Action: ' || lc_action || ' SQLCODE: ' || SQLCODE || ' SQLERRM: ' || SQLERRM);

  END process_item_cost;
  
  /**********************************
  * Helper procedure to calculate tax
  **********************************/
  
  PROCEDURE process_tax(p_program_setups      IN            gt_translation_values,
                        p_contract_info       IN            xx_ar_contracts%ROWTYPE,
                        px_subscription_array IN OUT NOCOPY subscription_table)
  IS
  
    lc_procedure_name    CONSTANT  VARCHAR2(61) := gc_package_name || '.' || 'process_tax';

    lt_parameters                  gt_input_parameters;

    lc_action                      VARCHAR2(1000);

    lc_error                       VARCHAR2(1000);
    
    lr_subscription_error_info     xx_ar_subscriptions_error%ROWTYPE;
    
    le_processing                  EXCEPTION;
     
   BEGIN

    entering_sub(p_procedure_name  => lc_procedure_name,
                 p_parameters      => lt_parameters);

    lc_action := 'Looping thru subscription array';


    FOR indx IN 1 .. px_subscription_array.COUNT
    LOOP

      BEGIN
        IF px_subscription_array(indx).tax_amount IS NULL
        THEN

          lc_action := 'Calling get_contract_line_info';
          
          IF p_program_setups('tax_enabled_flag') = 'Y'
          THEN
            --tax is calculated by calling EAI service for $1 for one line and same is prorated to all other lines of a contract
            NULL;
  
          ELSE
          
            lc_action := 'updating tax_amount and total_contract_amount';
            
            px_subscription_array(indx).tax_amount            := 0;
            px_subscription_array(indx).total_contract_amount := px_subscription_array(indx).contract_line_amount;
        
          END IF;
        
        END IF;
                 
        lc_action := 'Calling update_subscription_info';

        update_subscription_info(px_subscription_info => px_subscription_array(indx));
      
      EXCEPTION
        WHEN OTHERS
        THEN

          lr_subscription_error_info.contract_id             := px_subscription_array(indx).contract_id;
          lr_subscription_error_info.contract_number         := px_subscription_array(indx).contract_number;
          lr_subscription_error_info.contract_line_number    := px_subscription_array(indx).contract_line_number;
          lr_subscription_error_info.billing_sequence_number := px_subscription_array(indx).billing_sequence_number;
          lr_subscription_error_info.error_module            := lc_procedure_name;
          lr_subscription_error_info.error_message           := SUBSTR('Action: ' || lc_action || ' Error: ' || SQLCODE || ' ' || SQLERRM, 1, gc_max_err_size);
          lr_subscription_error_info.creation_date           := SYSDATE;

          lc_action := 'Calling insert_subscription_error_info';

          insert_subscription_error_info(p_subscription_error_info => lr_subscription_error_info);

          lc_error := lr_subscription_error_info.error_message;

          RAISE le_processing;
      END;
    END LOOP;

    exiting_sub(p_procedure_name => lc_procedure_name);

  EXCEPTION
  WHEN le_processing
  THEN
    exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => TRUE);
    RAISE_APPLICATION_ERROR(-20101, 'PROCEDURE: ' || lc_procedure_name || ' ERROR: ' || lc_error);
  WHEN OTHERS
  THEN
    exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => TRUE);
    RAISE_APPLICATION_ERROR(-20101, 'PROCEDURE: ' || lc_procedure_name || ' Action: ' || lc_action || ' SQLCODE: ' || SQLCODE || ' SQLERRM: ' || SQLERRM);

  END process_tax;
  
  /**********************************************
  * Helper procedure to get POS order information
  **********************************************/

  PROCEDURE get_pos_ordt_info(p_order_number IN         xx_ar_order_receipt_dtl.orig_sys_document_ref%TYPE,
                              x_ordt_info    OUT NOCOPY xx_ar_order_receipt_dtl%ROWTYPE)
  IS

    lc_procedure_name  CONSTANT VARCHAR2(61) := gc_package_name || '.' || 'get_pos_ordt_info';
    lt_parameters      gt_input_parameters;

  BEGIN

    lt_parameters('p_order_number') := p_order_number;

    entering_sub(p_procedure_name  => lc_procedure_name,
                 p_parameters      => lt_parameters);

    SELECT *
    INTO   x_ordt_info
    FROM   xx_ar_order_receipt_dtl
    WHERE  orig_sys_document_ref = p_order_number
      AND  payment_type_code     = 'CREDIT_CARD'
      AND  rownum                = 1;--Added to fix -> NAIT-125675 and NAIT-126620

    logit(p_message => 'RESULT header_id: ' || x_ordt_info.header_id);

    exiting_sub(p_procedure_name => lc_procedure_name);

    EXCEPTION
    WHEN OTHERS
    THEN
      exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => TRUE);
      RAISE_APPLICATION_ERROR(-20101, 'PROCEDURE: ' || lc_procedure_name || ' SQLCODE: ' || SQLCODE || ' SQLERRM: ' || SQLERRM);

  END get_pos_ordt_info;
  
  /****************************************
  * Helper procedure to get POS information
  ****************************************/

  PROCEDURE get_pos_info(p_header_id        IN         oe_order_headers_all.header_id%TYPE,
                         p_orig_sys_doc_ref IN         xx_ar_order_receipt_dtl.orig_sys_document_ref%TYPE,
                         x_pos_info         OUT NOCOPY xx_ar_pos_inv_order_ref%ROWTYPE)
  IS

    lc_procedure_name  CONSTANT VARCHAR2(61) := gc_package_name || '.' || 'get_pos_info';
    lt_parameters      gt_input_parameters;

  BEGIN

    lt_parameters('p_header_id') := p_header_id;

    entering_sub(p_procedure_name  => lc_procedure_name,
                 p_parameters      => lt_parameters);

    SELECT *
    INTO   x_pos_info
    FROM   xx_ar_pos_inv_order_ref
    WHERE  oe_header_id = p_header_id;

    logit(p_message => 'RESULT trx_number: ' || x_pos_info.summary_trx_number);
    logit(p_message => 'RESULT order_number: ' || x_pos_info.sales_order);


    exiting_sub(p_procedure_name => lc_procedure_name);

    EXCEPTION
     WHEN NO_DATA_FOUND THEN
      BEGIN
        SELECT header_id,order_number 
        INTO x_pos_info.oe_header_id,x_pos_info.sales_order 
        FROM oe_order_headers_all
        WHERE orig_sys_document_ref = p_orig_sys_doc_ref;
        -- Added for NAIT-125836-Invoice creation is failing with no_data_found trying to find the initial POS order
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          SELECT header_id,order_number 
          INTO x_pos_info.oe_header_id,x_pos_info.sales_order 
          FROM XXOM_OE_ORDER_HEADERS_ALL_HIST
          WHERE orig_sys_document_ref = p_orig_sys_doc_ref;
      END;
   -- END for NAIT-125836-Invoice creation is failing with no_data_found trying to find the initial POS order 
      BEGIN
        SELECT trx_number 
        INTO x_pos_info.summary_trx_number 
        FROM ra_customer_trx_all
        WHERE interface_header_attribute1 = x_pos_info.sales_order ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          x_pos_info.summary_trx_number := NULL;
          logit(p_message => 'Invoice not yet created ' || x_pos_info.summary_trx_number);
      END;
    logit(p_message => 'RESULT POS trx_number: ' || x_pos_info.summary_trx_number);
    logit(p_message => 'RESULT POS order_number: ' || x_pos_info.sales_order);

    exiting_sub(p_procedure_name => lc_procedure_name);

    WHEN OTHERS
    THEN
      exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => TRUE);
      RAISE_APPLICATION_ERROR(-20101, 'PROCEDURE: ' || lc_procedure_name || ' SQLCODE: ' || SQLCODE || ' SQLERRM: ' || SQLERRM);

  END get_pos_info;

  /************************************************
  * Helper procedure to get item master information
  ************************************************/

  PROCEDURE get_item_master_info(p_item_name        IN         mtl_system_items_b.segment1%TYPE,
                                 x_item_master_info OUT NOCOPY mtl_system_items_b%ROWTYPE)
  IS

    lc_procedure_name  CONSTANT VARCHAR2(61) := gc_package_name || '.' || 'get_item_master_info';
    lt_parameters      gt_input_parameters;

  BEGIN

    lt_parameters('p_item_name') := p_item_name;

    entering_sub(p_procedure_name  => lc_procedure_name,
                 p_parameters      => lt_parameters);
    SELECT msib.*
    INTO   x_item_master_info
    FROM   mtl_system_items_b msib,
           mtl_parameters mp
    WHERE  msib.segment1               = p_item_name
    AND    mp.organization_id          = msib.organization_id
    AND    mp.master_organization_id   = mp.organization_id;

    logit(p_message => 'RESULT inventory item id ' || x_item_master_info.inventory_item_id);
    logit(p_message => 'RESULT organization id ' || x_item_master_info.organization_id);
    logit(p_message => 'RESULT unit of measure ' || x_item_master_info.primary_uom_code);

    exiting_sub(p_procedure_name => lc_procedure_name);

    EXCEPTION
    WHEN OTHERS
    THEN
      exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => TRUE);
      RAISE_APPLICATION_ERROR(-20101, 'PROCEDURE: ' || lc_procedure_name || ' SQLCODE: ' || SQLCODE || ' SQLERRM: ' || SQLERRM);

  END get_item_master_info;

  /****************************************************
  * Helper procedure to get unit of measure information
  ****************************************************/

  PROCEDURE get_uom_info(p_uom_code IN         mtl_units_of_measure.uom_code%TYPE,
                         x_uom_info OUT NOCOPY mtl_units_of_measure%ROWTYPE)
  IS

    lc_procedure_name  CONSTANT VARCHAR2(61) := gc_package_name || '.' || 'get_uom_info';
    lt_parameters      gt_input_parameters;

  BEGIN

    lt_parameters('p_uom_code') := p_uom_code;

    entering_sub(p_procedure_name  => lc_procedure_name,
                 p_parameters      => lt_parameters);

    SELECT muom.*
    INTO   x_uom_info
    FROM   mtl_units_of_measure muom
    WHERE  muom.uom_code = p_uom_code;

    logit(p_message => 'RESULT unit of measure ' || x_uom_info.unit_of_measure);

    exiting_sub(p_procedure_name => lc_procedure_name);

    EXCEPTION
    WHEN OTHERS
    THEN
      exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => TRUE);
      RAISE_APPLICATION_ERROR(-20101, 'PROCEDURE: ' || lc_procedure_name || ' SQLCODE: ' || SQLCODE || ' SQLERRM: ' || SQLERRM);

  END get_uom_info;

  /**************************************************
  * Helper procedure to get item category information
  **************************************************/

  PROCEDURE get_item_category_info(p_inventory_item_id   IN         mtl_system_items_b.inventory_item_id%TYPE,
                                   p_organization_id     IN         mtl_system_items_b.organization_id%TYPE,
                                   p_category_set_name   IN         mtl_category_sets.category_set_name%TYPE,
                                   x_item_category_info  OUT NOCOPY mtl_categories_b%ROWTYPE)
  IS

    lc_procedure_name  CONSTANT VARCHAR2(61) := gc_package_name || '.' || 'get_item_category_info';
    lt_parameters      gt_input_parameters;

  BEGIN

    lt_parameters('p_inventory_item_id') := p_inventory_item_id;
    lt_parameters('p_organization_id')   := p_organization_id;
    lt_parameters('p_category_set_name') := p_category_set_name;

    entering_sub(p_procedure_name  => lc_procedure_name,
                 p_parameters      => lt_parameters);

    SELECT mc.*
    INTO   x_item_category_info
    FROM   mtl_item_categories mic,
           mtl_categories_b mc,
           mtl_category_sets mcs
    WHERE mic.category_set_id   = mcs.category_set_id
    AND   mic.category_id       = mc.category_id
    AND   mic.inventory_item_id = p_inventory_item_id
    AND   mic.organization_id   = p_organization_id
    AND   mcs.category_set_name = p_category_set_name;

    logit(p_message => 'RESULT segment 3 ' || x_item_category_info.segment3);

    exiting_sub(p_procedure_name => lc_procedure_name);

    EXCEPTION
    WHEN OTHERS
    THEN
      exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => TRUE);
      RAISE_APPLICATION_ERROR(-20101, 'PROCEDURE: ' || lc_procedure_name || ' SQLCODE: ' || SQLCODE || ' SQLERRM: ' || SQLERRM);

  END get_item_category_info;

  /****************************************
  * Helper procedure to decrypt credit card
  ****************************************/

  PROCEDURE decrypt_credit_card(p_context_namespace   IN          VARCHAR2,
                                p_context_attribute   IN          VARCHAR2,
                                p_context_value       IN          VARCHAR2,
                                p_module              IN          VARCHAR2,
                                p_format              IN          VARCHAR2,
                                p_encrypted_value     IN          xx_ar_contracts.card_token%TYPE,
                                p_key_label           IN          xx_ar_contracts.card_encryption_label%TYPE,
                                x_decrypted_value     OUT NOCOPY  VARCHAR2)
  IS

    lc_procedure_name  CONSTANT VARCHAR2(61) := gc_package_name || '.' || 'decrypt_credit_card';
    lt_parameters      gt_input_parameters;

    lc_action          VARCHAR2(1000);
    lc_error_message   VARCHAR2(2000);
    le_processing      EXCEPTION;

  BEGIN

    lt_parameters('p_context_namespace') := p_context_namespace;
    lt_parameters('p_context_attribute') := p_context_attribute;
    lt_parameters('p_context_value')     := p_context_value;
    lt_parameters('p_module')            := p_module;
    lt_parameters('p_format')            := p_format;
    lt_parameters('p_encrypted_value')   := '********************';
    lt_parameters('p_key_label')         := p_key_label;

    entering_sub(p_procedure_name  => lc_procedure_name,
                 p_parameters      => lt_parameters);

    lc_action := 'Setting context';

    DBMS_SESSION.set_context(namespace => p_context_namespace,
                             attribute => p_context_attribute,
                             value     => p_context_value);

    lc_action := 'Decrypt credit card';

    xx_od_security_key_pkg.decrypt(p_module        => p_module,
                                   p_key_label     => p_key_label,
                                   p_encrypted_val => p_encrypted_value,
                                   p_format        => p_format,
                                   x_decrypted_val => x_decrypted_value,
                                   x_error_message => lc_error_message);

    IF (x_decrypted_value IS NULL)
    THEN
      lc_error_message := 'Unable to decrypted: ' || lc_error_message;
      RAISE le_processing;
    END IF;

    exiting_sub(p_procedure_name => lc_procedure_name);

    EXCEPTION
    WHEN le_processing
    THEN
      exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => TRUE);
      RAISE_APPLICATION_ERROR(-20101, 'PROCEDURE: ' || lc_procedure_name || 'ACTION ' || lc_action || ' ERROR: ' || lc_error_message);
    WHEN OTHERS
    THEN
      exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => TRUE);
      RAISE_APPLICATION_ERROR(-20101, 'PROCEDURE: ' || lc_procedure_name || 'ACTION ' || lc_action || ' SQLCODE: ' || SQLCODE || ' SQLERRM: ' || SQLERRM);

  END decrypt_credit_card;

  /****************************************
  * Helper procedure to encrypt credit card
  ****************************************/

  PROCEDURE encrypt_credit_card(p_context_namespace   IN          VARCHAR2,
                                p_context_attribute   IN          VARCHAR2,
                                p_context_value       IN          VARCHAR2,
                                p_module              IN          VARCHAR2,
                                p_algorithm           IN          VARCHAR2,
                                p_decrypted_value     IN          xx_ar_contracts.card_token%TYPE,
                                x_encrypted_value     OUT NOCOPY  xx_ar_contracts.card_token%TYPE,
                                x_key_label           OUT NOCOPY  xx_ar_contracts.card_encryption_label%TYPE)
  IS

    lc_procedure_name  CONSTANT VARCHAR2(61) := gc_package_name || '.' || 'encrypt_credit_card';
    lt_parameters      gt_input_parameters;

    lc_action          VARCHAR2(1000);
    lc_error_message   VARCHAR2(2000);
    le_processing      EXCEPTION;

  BEGIN

    lt_parameters('p_context_namespace') := p_context_namespace;
    lt_parameters('p_context_attribute') := p_context_attribute;
    lt_parameters('p_context_value')     := p_context_value;
    lt_parameters('p_module')            := p_module;
    lt_parameters('p_algorithm')         := p_algorithm;
    lt_parameters('p_decrypted_value')   := '********************';

    entering_sub(p_procedure_name  => lc_procedure_name,
                 p_parameters      => lt_parameters);

    lc_action := 'Setting context';

    DBMS_SESSION.set_context(namespace => p_context_namespace,
                             attribute => p_context_attribute,
                             value     => p_context_value);

    lc_action := 'Decrypt credit card';

    xx_od_security_key_pkg.encrypt_outlabel(p_module        => p_module,
                                            p_key_label     => NULL,
                                            p_algorithm     => p_algorithm,
                                            p_decrypted_val => p_decrypted_value,
                                            x_encrypted_val => x_encrypted_value,
                                            x_error_message => lc_error_message,
                                            x_key_label     => x_key_label);

    IF (x_encrypted_value IS NULL OR x_key_label IS NULL)
    THEN
      lc_error_message := 'Unable to encrypt value: ' || lc_error_message;
      RAISE le_processing;
    END IF;

    exiting_sub(p_procedure_name => lc_procedure_name);

    EXCEPTION
    WHEN le_processing
    THEN
      exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => TRUE);
      RAISE_APPLICATION_ERROR(-20101, 'PROCEDURE: ' || lc_procedure_name || 'ACTION ' || lc_action || ' ERROR: ' || lc_error_message);
    WHEN OTHERS
    THEN
      exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => TRUE);
      RAISE_APPLICATION_ERROR(-20101, 'PROCEDURE: ' || lc_procedure_name || 'ACTION ' || lc_action || ' SQLCODE: ' || SQLCODE || ' SQLERRM: ' || SQLERRM);

  END encrypt_credit_card;
  
  /***********************************************
  * Helper procedure to get hr operating unit info
  ***********************************************/

  PROCEDURE get_operating_unit_info(p_ord_id                IN         hr_operating_units.organization_id%TYPE,
                                    x_operating_unit_info   OUT NOCOPY hr_operating_units%ROWTYPE)
  IS

    lc_procedure_name  CONSTANT VARCHAR2(61) := gc_package_name || '.' || 'get_operating_unit_info';
    lt_parameters      gt_input_parameters;

  BEGIN

    lt_parameters('p_ord_id') := p_ord_id;
    
    entering_sub(p_procedure_name  => lc_procedure_name,
                 p_parameters      => lt_parameters);
                 
    SELECT *
    INTO   x_operating_unit_info
    FROM   hr_operating_units
    WHERE  organization_id = p_ord_id;

    logit(p_message => 'RESULT organization_id: ' || x_operating_unit_info.organization_id);
    logit(p_message => 'RESULT set_of_books_id: ' || x_operating_unit_info.set_of_books_id);

    exiting_sub(p_procedure_name => lc_procedure_name);

    EXCEPTION
    WHEN OTHERS
    THEN
      exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => TRUE);
      RAISE_APPLICATION_ERROR(-20101, 'PROCEDURE: ' || lc_procedure_name || ' SQLCODE: ' || SQLCODE || ' SQLERRM: ' || SQLERRM);

  END get_operating_unit_info;

  /***********************************************
  * Helper procedure to get hr operating unit info
  ***********************************************/

  PROCEDURE get_batch_source_info(p_trx_source        IN         VARCHAR2,
                                  p_ord_id            IN         hr_operating_units.organization_id%TYPE,
                                  x_batch_source_id   OUT NOCOPY ra_batch_sources_all.batch_source_id%TYPE)
  IS

    lc_procedure_name  CONSTANT VARCHAR2(61) := gc_package_name || '.' || 'get_batch_source_info';
    lt_parameters      gt_input_parameters;

  BEGIN
     
     lt_parameters('p_trx_source') := p_trx_source;
     lt_parameters('p_ord_id')     := p_ord_id;
     
     entering_sub(p_procedure_name  => lc_procedure_name,
                  p_parameters      => lt_parameters);
                 
     SELECT rbs.batch_source_id
     INTO   x_batch_source_id
     FROM   ra_batch_sources_all rbs
     WHERE  rbs.NAME = p_trx_source
     AND    rbs.status = 'A'
     AND    rbs.org_id = p_ord_id;

    logit(p_message => 'RESULT batch_source_id: ' || x_batch_source_id);

    exiting_sub(p_procedure_name => lc_procedure_name);

    EXCEPTION
    WHEN OTHERS
    THEN
      exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => TRUE);
      RAISE_APPLICATION_ERROR(-20101, 'PROCEDURE: ' || lc_procedure_name || ' SQLCODE: ' || SQLCODE || ' SQLERRM: ' || SQLERRM);

  END get_batch_source_info;
  
  /**********************************************
  * Helper procedure to get cust transaction type
  **********************************************/

  PROCEDURE get_cust_trx_type_info(p_trx_type        IN         VARCHAR2,
                                   x_cust_trx_type   OUT NOCOPY ra_cust_trx_types_all%ROWTYPE)
  IS

    lc_procedure_name  CONSTANT VARCHAR2(61) := gc_package_name || '.' || 'get_cust_trx_type_info';
    lt_parameters      gt_input_parameters;

  BEGIN
     
     lt_parameters('p_trx_type') := p_trx_type;
     
     entering_sub(p_procedure_name  => lc_procedure_name,
                  p_parameters      => lt_parameters);
                 
     SELECT rctt.*
     INTO   x_cust_trx_type
     FROM   ra_cust_trx_types_all rctt
           ,hr_operating_units hou
     WHERE  1 = 1
     AND    rctt.NAME = p_trx_type
     AND    rctt.org_id = hou.organization_id
     AND    hou.NAME = 'OU_US';

    logit(p_message => 'RESULT NAME: '             || x_cust_trx_type.NAME);
    logit(p_message => 'RESULT cust_trx_type_id: ' || x_cust_trx_type.cust_trx_type_id);
    logit(p_message => 'RESULT TYPE: '             || x_cust_trx_type.TYPE);

    exiting_sub(p_procedure_name => lc_procedure_name);

    EXCEPTION
    WHEN OTHERS
    THEN
      exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => TRUE);
      RAISE_APPLICATION_ERROR(-20101, 'PROCEDURE: ' || lc_procedure_name || ' SQLCODE: ' || SQLCODE || ' SQLERRM: ' || SQLERRM);

  END get_cust_trx_type_info;
  
  /******************************************
  * Helper procedure to get payment term info
  ******************************************/

  PROCEDURE get_term_info(p_cust_trx_type IN ra_cust_trx_types_all.TYPE%TYPE,
                          x_terms   OUT NOCOPY ra_terms%ROWTYPE)
  IS

    lc_procedure_name  CONSTANT VARCHAR2(61) := gc_package_name || '.' || 'get_term_info';
    lt_parameters      gt_input_parameters;

  BEGIN
     
     lt_parameters('p_cust_trx_type') := p_cust_trx_type;
     
     entering_sub(p_procedure_name  => lc_procedure_name,
                  p_parameters      => lt_parameters);
                 
     IF p_cust_trx_type <> 'CM'
     THEN
       BEGIN
         SELECT rt.*
         INTO   x_terms
         FROM   hz_cust_profile_classes cpc, 
                ra_terms rt
         WHERE  cpc.standard_terms = rt.term_id
         AND    cpc.NAME = 'CREDIT_CARD';
       EXCEPTION
         WHEN OTHERS THEN
           exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => TRUE);
           RAISE_APPLICATION_ERROR(-20101, 'PROCEDURE: ' || lc_procedure_name || ' SQLCODE: ' || SQLCODE || ' SQLERRM: ' || SQLERRM);
       END;
     ELSE
       x_terms := NULL;
     END IF;

     logit(p_message => 'RESULT term_id: '  || x_terms.term_id);
     logit(p_message => 'RESULT NAME: '     || x_terms.NAME);

    exiting_sub(p_procedure_name => lc_procedure_name);

    EXCEPTION
    WHEN OTHERS
    THEN
      exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => TRUE);
      RAISE_APPLICATION_ERROR(-20101, 'PROCEDURE: ' || lc_procedure_name || ' SQLCODE: ' || SQLCODE || ' SQLERRM: ' || SQLERRM);

  END get_term_info;
  
  /***************************************************
  * Helper procedure to get invoice sequence counter
  *************************************************/

  PROCEDURE get_inv_seq_counter(p_contract_number   IN         xx_ar_subscriptions.contract_number%TYPE,
                                x_inv_seq_counter   OUT NOCOPY xx_ar_subscriptions.inv_seq_counter%TYPE)
  IS

    lc_procedure_name  CONSTANT VARCHAR2(61) := gc_package_name || '.' || 'get_inv_seq_counter';
    lt_parameters      gt_input_parameters;
    ln_loop_counter    NUMBER := 0;

  BEGIN
     
    lt_parameters('p_contract_number') := p_contract_number;
    
    entering_sub(p_procedure_name  => lc_procedure_name,
                 p_parameters      => lt_parameters);
      
    SELECT MAX(NVL(inv_seq_counter,0)) + 1
    INTO   x_inv_seq_counter
    FROM   xx_ar_subscriptions
    WHERE  contract_number = p_contract_number;
                     
    logit(p_message => 'RESULT invoice sequence counter: '  || x_inv_seq_counter);
    
    exiting_sub(p_procedure_name => lc_procedure_name);

  EXCEPTION
    WHEN OTHERS
    THEN
      exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => TRUE);
      RAISE_APPLICATION_ERROR(-20101, 'PROCEDURE: ' || lc_procedure_name || ' SQLCODE: ' || SQLCODE || ' SQLERRM: ' || SQLERRM);

  END get_inv_seq_counter;
   
  /*********************************************************************************
  * Helper procedure to get payment term based from customer profile for AB Customer
  *********************************************************************************/

  PROCEDURE get_term_ab_info(p_cust_acct_id IN         hz_cust_accounts.cust_account_id%TYPE,
                             x_terms        OUT NOCOPY ra_terms%ROWTYPE)
  IS

    lc_procedure_name  CONSTANT VARCHAR2(61) := gc_package_name || '.' || 'get_term_ab_info';
    lt_parameters      gt_input_parameters;

  BEGIN
     
     lt_parameters('p_cust_acct_id') := p_cust_acct_id;
     
     entering_sub(p_procedure_name  => lc_procedure_name,
                  p_parameters      => lt_parameters);
                 
     BEGIN
       SELECT rt.*
       INTO   x_terms
       FROM   hz_customer_profiles hcp
             ,ra_terms rt
       WHERE  hcp.standard_terms = rt.term_id
       AND    hcp.cust_account_id = p_cust_acct_id
       AND    hcp.site_use_id IS NULL;
     EXCEPTION
       WHEN OTHERS THEN
         exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => TRUE);
         RAISE_APPLICATION_ERROR(-20101, 'PROCEDURE: ' || lc_procedure_name || ' SQLCODE: ' || SQLCODE || ' SQLERRM: ' || SQLERRM);
     END;
     
     logit(p_message => 'RESULT term_id: '  || x_terms.term_id);
     logit(p_message => 'RESULT NAME: '     || x_terms.NAME);
     
     exiting_sub(p_procedure_name => lc_procedure_name);

    EXCEPTION
    WHEN OTHERS
    THEN
      exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => TRUE);
      RAISE_APPLICATION_ERROR(-20101, 'PROCEDURE: ' || lc_procedure_name || ' SQLCODE: ' || SQLCODE || ' SQLERRM: ' || SQLERRM);

  END get_term_ab_info;
  

  /******************************************************
  * Helper procedure to check credit limit of AB customer
  ******************************************************/

  PROCEDURE get_credit_limit_check(p_contract_info            IN         xx_ar_contracts%ROWTYPE,
                                   p_billing_sequence_number  IN         xx_ar_subscriptions.billing_sequence_number%TYPE,
                                   p_invoice_number           IN         xx_ar_subscriptions.invoice_number%TYPE,
                                   x_credit_check_flag        OUT NOCOPY VARCHAR2)
  IS

    lc_procedure_name  CONSTANT VARCHAR2(61) := gc_package_name || '.' || 'get_credit_limit_check';
    lt_parameters      gt_input_parameters;
    
    l_errbuf           VARCHAR2(200)         := NULL;
    l_retcode          NUMBER                := 0; 
    l_response_text    xx_ar_otb_transactions.response_text%TYPE;
    l_amount           xx_ar_subscriptions.total_contract_amount%TYPE;
    
    lr_invoice_header_info         ra_customer_trx_all%ROWTYPE;

    ln_invoice_total_amount_info   ra_customer_trx_lines_all.extended_amount%TYPE;
    
    lc_action                      VARCHAR2(256)   := NULL;
    
  BEGIN

    entering_sub(p_procedure_name  => lc_procedure_name,
                 p_parameters      => lt_parameters);
                   
    /************************
    * Get invoice information
    ************************/
    
    lc_action := 'Calling get_invoice_header_info';
    
    get_invoice_header_info(p_invoice_number      => p_invoice_number,
                            x_invoice_header_info => lr_invoice_header_info);
    /******************************
    * Get invoice total information
    ******************************/
    
    lc_action := 'Calling get_invoice_total_amount_info';
    
    get_invoice_total_amount_info(p_customer_trx_id           => lr_invoice_header_info.customer_trx_id,
                                  x_invoice_total_amount_info => ln_invoice_total_amount_info);
    
    XX_AR_CREDIT_CHECK_WRAPPER_PKG.CREDIT_CHECK_WRAPPER(
                                                         errbuf          => l_errbuf,
                                                         retcode         => l_retcode,
                                                         p_store_num     => p_contract_info.store_number,
                                                         p_register_num  => '99',
                                                         p_sale_tran     => NULL,
                                                         p_order_num     => SUBSTR(p_contract_info.contract_name,1,9),
                                                         p_sub_order_num => SUBSTR(p_contract_info.contract_name,11,13),
                                                         p_account_num   => p_contract_info.bill_to_osr,
                                                         p_amt           => ln_invoice_total_amount_info,
                                                         p_updt_flag     => 'Y'
                                                        );
    
    --checking credit card limit status
    SELECT response_text
    INTO   l_response_text
    FROM   xx_ar_otb_transactions
    WHERE  order_num         = SUBSTR(p_contract_info.contract_name,1,9)
    AND    creation_date     = (SELECT MAX(creation_date)
                                FROM   xx_ar_otb_transactions
                                WHERE  order_num         = SUBSTR(p_contract_info.contract_name,1,9));
    
    IF UPPER(l_response_text) = 'APPROVAL'
    THEN
      x_credit_check_flag := 'Y';
    ELSE
      x_credit_check_flag := 'N';
    END IF;
    
    exiting_sub(p_procedure_name => lc_procedure_name);

    EXCEPTION
    WHEN OTHERS
    THEN
      exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => TRUE);
      RAISE_APPLICATION_ERROR(-20101, 'PROCEDURE: ' || lc_procedure_name || ' SQLCODE: ' || SQLCODE || ' SQLERRM: ' || SQLERRM);

  END get_credit_limit_check;
  
  /*********************************************************************************************
  * Helper procedure to send email to credit department when customer does not meet credit limit
  *********************************************************************************************/

  PROCEDURE send_email_AB(p_contract_info            IN         xx_ar_contracts%ROWTYPE,
                          p_billing_sequence_number  IN         xx_ar_subscriptions.billing_sequence_number%TYPE,
                          p_invoice_number           IN         xx_ar_subscriptions.invoice_number%TYPE,
                          p_AB_flag                  OUT NOCOPY VARCHAR2)
  IS

    lc_procedure_name              CONSTANT VARCHAR2(61) := gc_package_name || '.' || 'send_email_AB';
    lt_parameters                  gt_input_parameters;
                                   
    lc_action                      VARCHAR2(256)   := NULL;
                                   
    lt_translation_info            xx_fin_translatevalues%ROWTYPE;
                                   
    lc_conn                        UTL_SMTP.connection;
                                   
    lc_message                     VARCHAR2(2000) := NULL;
    
    lr_invoice_header_info         ra_customer_trx_all%ROWTYPE;

    ln_invoice_total_amount_info   ra_customer_trx_lines_all.extended_amount%TYPE;
    
    lr_customer_info               hz_cust_accounts%ROWTYPE;
    
  BEGIN

    entering_sub(p_procedure_name  => lc_procedure_name,
                 p_parameters      => lt_parameters);
                   
    /**********************************************
    * Get customer information based on AOPS number
    **********************************************/
    
    lc_action := 'Calling get_customer_pos_info for customer information';
    
    get_customer_pos_info(p_aops           => p_contract_info.bill_to_osr,
                          x_customer_info  => lr_customer_info);
                          
    /************************
    * Get invoice information
    ************************/
    
    lc_action := 'Calling get_invoice_header_info';
    
    get_invoice_header_info(p_invoice_number      => p_invoice_number,
                            x_invoice_header_info => lr_invoice_header_info);
    /******************************
    * Get invoice total information
    ******************************/
    
    lc_action := 'Calling get_invoice_total_amount_info';
    
    get_invoice_total_amount_info(p_customer_trx_id           => lr_invoice_header_info.customer_trx_id,
                                  x_invoice_total_amount_info => ln_invoice_total_amount_info);
                 
    lc_message := 'Recurring Subscription Order - Credit Limit Review'||CHR(13)||CHR(13)||
                  LPAD('Customer account name : ',42)        ||lr_customer_info.account_name||CHR(13)||
                  LPAD('Customer account number : ',44)      ||lr_customer_info.account_number||CHR(13)||--change to account#
                  LPAD('Recurring Invoice number : ',45)     ||p_invoice_number||CHR(13)||
                  LPAD('Amount of recurring invoice : ',48)  ||'$'||LTRIM(TO_CHAR(ln_invoice_total_amount_info,'99G999G990D00'))||CHR(13)||
                  LPAD('Date of the recurring invoice : ',50)||TO_CHAR(lr_invoice_header_info.trx_date,'DD-MON-YYYY')||CHR(13)||
                  LPAD('(Subscription) Contract # : ',46)    ||p_contract_info.contract_number
                  ;
                 
    /*****************
    * Get enable debug
    *****************/

    lc_action :=  'Calling get_translation_info for credit department email information ';
    
    lt_translation_info := NULL;
    
    lt_translation_info.source_value1 := 'EMAIL_INFO';
    
    get_translation_info(p_translation_name  => 'SUBSCRIPTIONS_AB_EMAIL',
                         px_translation_info => lt_translation_info);
    
    lc_action :=  'Calling xx_pa_pb_mail.begin_mail';
    lc_conn := xx_pa_pb_mail.begin_mail(sender        => lt_translation_info.target_value1,
                                        recipients    => lt_translation_info.target_value2,
                                        cc_recipients => lt_translation_info.target_value3,
                                        subject       => lt_translation_info.target_value4,
                                        mime_type     => xx_pa_pb_mail.multipart_mime_type);
    
    lc_action :=  'Calling xx_pa_pb_mail.attach_text';
    xx_pa_pb_mail.attach_text( conn => lc_conn,
                               data =>  lc_message||CHR(13)||CHR(13)
                                      ||lt_translation_info.target_value5||CHR(13)||CHR(13)
                                      ||lt_translation_info.target_value6||CHR(13)||CHR(13)
                                      ||lt_translation_info.target_value7||CHR(13)
                                      ||lt_translation_info.target_value8||CHR(13)
                                      ||lt_translation_info.target_value9||CHR(13)||CHR(13)
                                      ||lt_translation_info.target_value10||CHR(13)
                              );
    
    lc_action :=  'Calling xx_pa_pb_mail.end_mail';
    xx_pa_pb_mail.end_mail( conn => lc_conn );
    
    COMMIT;
    
    p_AB_flag := 'Y';
    
    logit(p_message => 'Email sent successfully');

    exiting_sub(p_procedure_name => lc_procedure_name);

    EXCEPTION
    WHEN OTHERS
    THEN
      p_AB_flag := 'N';
      exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => TRUE);
      RAISE_APPLICATION_ERROR(-20101, 'PROCEDURE: ' || lc_procedure_name || ' SQLCODE: ' || SQLCODE || ' SQLERRM: ' || SQLERRM);

  END send_email_AB;
  
  /************************************************
  * Helper procedure to get store close information
  ************************************************/

  PROCEDURE get_store_close_info(p_store_number  IN        VARCHAR2,
                                 x_store_info   OUT NOCOPY VARCHAR2)
  IS

    lc_procedure_name  CONSTANT VARCHAR2(61) := gc_package_name || '.' || 'get_store_close_info';
    lt_parameters      gt_input_parameters;
    lt_cnt             NUMBER;

  BEGIN

    lt_parameters('p_store_number')          := p_store_number;

    entering_sub(p_procedure_name  => lc_procedure_name,
                 p_parameters      => lt_parameters);
   
     
    /**********************************************************
    * Checking if Store is available in Store Close translation
    **********************************************************/
 
    SELECT   COUNT(1)
    INTO   lt_cnt
    FROM   xx_fin_translatevalues                     vals,
           xx_fin_translatedefinition                 defn
    WHERE   defn.translate_id                        = vals.translate_id
    AND   defn.translation_name                    = 'SUBSCRIPTION_STORE_CLOSE'
    AND   lpad(vals.source_value3,6,'0')             = p_store_number
    AND   SYSDATE BETWEEN vals.start_date_active AND NVL(vals.end_date_active, SYSDATE + 1)
    AND   SYSDATE BETWEEN defn.start_date_active AND NVL(defn.end_date_active, SYSDATE + 1)
    AND   SYSDATE                                  >= to_date(vals.target_value4,'MM-DD-YYYY')
    AND   vals.enabled_flag                        = 'Y'
    AND   defn.enabled_flag                        = 'Y';
    
    IF lt_cnt>0 
    THEN

      BEGIN

        /*********************************************************
        * If Store is available in Store Close translation picking 
        * next available relocating store
        *********************************************************/
      
        SELECT  LPAD(vals.target_value2,6,'0')
        INTO  x_store_info
        FROM  xx_fin_translatevalues vals,
              xx_fin_translatedefinition defn
        WHERE   defn.translate_id                        = vals.translate_id
        AND   defn.translation_name                    = 'SUBSCRIPTION_STORE_CLOSE'
        AND   lpad(vals.source_value3,6,'0')             = p_store_number
        AND   SYSDATE BETWEEN vals.start_date_active AND NVL(vals.end_date_active, SYSDATE + 1)
        AND   SYSDATE BETWEEN defn.start_date_active AND NVL(defn.end_date_active, SYSDATE + 1)
        AND   SYSDATE                                  >= to_date(vals.target_value4,'MM-DD-YYYY')
        AND   vals.enabled_flag                        = 'Y'
        AND   defn.enabled_flag                        = 'Y';

        IF x_store_info IS NULL 
        THEN

          /**********************************************************
          * Getting Default store in case of missing relocating store
          **********************************************************/
          SELECT  LPAD(vals.target_value1,6,'0')
          INTO  x_store_info
          FROM  xx_fin_translatevalues vals,
                xx_fin_translatedefinition defn
          WHERE   defn.translate_id                        = vals.translate_id
          AND   defn.translation_name                    = 'XX_AR_SUBSCRIPTIONS'
          AND   vals.source_value1                       ='DEFAULT_STORE_CLOSE'
          AND   SYSDATE BETWEEN vals.start_date_active AND NVL(vals.end_date_active, SYSDATE + 1)
          AND   SYSDATE BETWEEN defn.start_date_active AND NVL(defn.end_date_active, SYSDATE + 1)
          AND   vals.enabled_flag                        = 'Y'
          AND   defn.enabled_flag                        = 'Y';
        END IF;
        
      EXCEPTION
        WHEN NO_DATA_FOUND 
        THEN

          /**********************************************************
          * Getting Default store in case of missing relocating store
          **********************************************************/

          SELECT  LPAD(vals.target_value1,6,'0')
          INTO  x_store_info
          FROM  xx_fin_translatevalues vals,
                xx_fin_translatedefinition defn
          WHERE   defn.translate_id                        = vals.translate_id
          AND   defn.translation_name                    = 'XX_AR_SUBSCRIPTIONS'
          AND   vals.source_value1                       ='DEFAULT_STORE_CLOSE'
          AND   SYSDATE BETWEEN vals.start_date_active AND NVL(vals.end_date_active, SYSDATE + 1)
          AND   SYSDATE BETWEEN defn.start_date_active AND NVL(defn.end_date_active, SYSDATE + 1)  
          AND   SYSDATE                                  >= to_date(vals.target_value4,'MM-DD-YYYY')
          AND   vals.enabled_flag                        = 'Y'
          AND   defn.enabled_flag                        = 'Y';
        
      WHEN OTHERS
      THEN
        exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => TRUE);
        RAISE_APPLICATION_ERROR(-20101, 'PROCEDURE: ' || lc_procedure_name || ' SQLCODE: ' || SQLCODE || ' SQLERRM: ' || SQLERRM);
      END;

    ELSE

      /*****************************************************************
      * If Store is not available in Store close, return existing store
      *****************************************************************/
      x_store_info  := p_store_number;
    END IF;

    logit(p_message => 'Return Store number: ' || x_store_info);
    exiting_sub(p_procedure_name => lc_procedure_name);

  EXCEPTION
    WHEN OTHERS
    THEN
      exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => TRUE);
      RAISE_APPLICATION_ERROR(-20101, 'PROCEDURE: ' || lc_procedure_name || ' SQLCODE: ' || SQLCODE || ' SQLERRM: ' || SQLERRM);

  END get_store_close_info;
  
  /*****************************************************
  * Helper procedure to get payment schedule information
  *****************************************************/

  PROCEDURE get_rec_activity_info(x_activity_id  OUT NOCOPY ar_receivables_trx.receivables_trx_id%TYPE)
  IS

    lc_procedure_name  CONSTANT VARCHAR2(61) := gc_package_name || '.' || 'get_rec_activity_info';
    lt_parameters               gt_input_parameters;
    lt_translation_info         xx_fin_translatevalues%ROWTYPE;
    lc_rec_activity_name        xx_fin_translatevalues.target_value1%TYPE;

  BEGIN

    entering_sub(p_procedure_name  => lc_procedure_name,
                 p_parameters      => lt_parameters);

    /**********************
    * Get rec activity name
    **********************/

    lt_translation_info := NULL;

    lt_translation_info.source_value1 := 'REC_ACTIVITY_NAME';

    get_translation_info(p_translation_name  => 'XX_AR_SUBSCRIPTIONS',
                         px_translation_info => lt_translation_info);

    lc_rec_activity_name  := lt_translation_info.target_value1;
    
    SELECT receivables_trx_id
    INTO   x_activity_id
    FROM   ar_receivables_trx_all
    WHERE  name   = lc_rec_activity_name
    AND    status = 'A';

    logit(p_message => 'RESULT activity_id: ' || x_activity_id);

    exiting_sub(p_procedure_name => lc_procedure_name);

    EXCEPTION
    WHEN OTHERS
    THEN
      exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => TRUE);
      RAISE_APPLICATION_ERROR(-20101, 'PROCEDURE: ' || lc_procedure_name || ' SQLCODE: ' || SQLCODE || ' SQLERRM: ' || SQLERRM);

  END get_rec_activity_info;
  
  /*****************************************************
  * Helper procedure to get payment schedule information
  *****************************************************/

  PROCEDURE get_payment_sch_info(p_cust_trx_id       IN         ra_customer_trx_all.customer_trx_id%TYPE,
                                 x_payment_sch_info  OUT NOCOPY ar_payment_schedules_all%ROWTYPE)
  IS

    lc_procedure_name  CONSTANT VARCHAR2(61) := gc_package_name || '.' || 'get_payment_sch_info';
    lt_parameters      gt_input_parameters;

  BEGIN

    lt_parameters('p_cust_trx_id') := p_cust_trx_id;

    entering_sub(p_procedure_name  => lc_procedure_name,
                 p_parameters      => lt_parameters);

    SELECT *
    INTO   x_payment_sch_info
    FROM   ar_payment_schedules_all
    WHERE  customer_trx_id = p_cust_trx_id;

    logit(p_message => 'RESULT payment_schedule_id: ' || x_payment_sch_info.payment_schedule_id);

    exiting_sub(p_procedure_name => lc_procedure_name);

    EXCEPTION
    WHEN OTHERS
    THEN
      exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => TRUE);
      RAISE_APPLICATION_ERROR(-20101, 'PROCEDURE: ' || lc_procedure_name || ' SQLCODE: ' || SQLCODE || ' SQLERRM: ' || SQLERRM);

  END get_payment_sch_info;

 /****************************************************
  * Helper procedure to populate ra_interface_lines_all
  ****************************************************/

  PROCEDURE populate_invoice_interface(p_program_setups      IN            gt_translation_values,
                                       p_contract_info       IN            xx_ar_contracts%ROWTYPE,
                                       px_subscription_array IN OUT NOCOPY subscription_table)
  IS

    lc_procedure_name    CONSTANT  VARCHAR2(61) := gc_package_name || '.' || 'populate_invoice_interface';

    lt_parameters                  gt_input_parameters;

    lc_action                      VARCHAR2(1000);

    lc_error                       VARCHAR2(1000);

    lr_order_header_info           oe_order_headers_all%ROWTYPE;
    
    lr_om_hdr_attribute_info       xx_om_header_attributes_all%ROWTYPE;
    
    lr_order_line_info             oe_order_lines_all%ROWTYPE;

    lr_invoice_header_info         ra_customer_trx_all%ROWTYPE;

    lr_invoice_line_info           ra_customer_trx_lines_all%ROWTYPE;

    lr_invoice_dist_info           ra_cust_trx_line_gl_dist_all%ROWTYPE;
    
    lr_customer_info               hz_cust_accounts%ROWTYPE;

    lr_contract_line_info          xx_ar_contract_lines%ROWTYPE;

    lr_bill_to_cust_acct_site_info hz_cust_acct_sites_all%ROWTYPE;

    lr_ship_to_cust_acct_site_info hz_cust_acct_sites_all%ROWTYPE;

    lr_bill_to_cust_site_osr_info  hz_orig_sys_references%ROWTYPE;

    lr_item_master_info            mtl_system_items_b%ROWTYPE;

    lr_uom_info                    mtl_units_of_measure%ROWTYPE;

    lr_item_category_info          mtl_categories_b%ROWTYPE;
    
    lr_sales_account_matrix_info   xx_fin_translatevalues%ROWTYPE;

    lr_subscription_error_info     xx_ar_subscriptions_error%ROWTYPE;

    lr_ra_intf_lines_info          ra_interface_lines_all%ROWTYPE;

    lr_ra_intf_dists_info          ra_interface_distributions_all%ROWTYPE;

    ln_trx_number                  NUMBER;

    ln_interface_line_id           NUMBER;

    ln_total_tax_amount            ra_interface_lines_all.amount%TYPE;

    lb_tax_interfaced_flag         BOOLEAN := FALSE;

    lc_invoice_interfaced_flag     xx_ar_subscriptions.invoice_interfaced_flag%TYPE;

    lc_invoice_interfacing_error   xx_ar_subscriptions.invoice_interfacing_error%TYPE;

    le_skip                        EXCEPTION;

    le_processing                  EXCEPTION;

    ln_invalid_interface_line_id   ra_interface_lines_all.interface_line_id%TYPE := 0;

    lc_invalid_inv_interface_flag  VARCHAR2(1) := 'N';
    
    lc_sloc                        hr_locations_all.location_code%TYPE;
    
    lc_ship_from_state             hr_locations_all.region_1%TYPE;
    
    lc_tax_state                   lr_om_hdr_attribute_info.ship_to_state%TYPE;
    
    lc_tax_loc                     fnd_flex_values.flex_value%TYPE;
    
    lc_sloc_type                   hr_lookups.meaning%TYPE;
                                 
    lc_oloc                        hr_locations_all.location_code%TYPE;
                                 
    lc_region                      hr_locations_all.region_1%TYPE;
                                 
    lc_oloc_type                   hr_lookups.meaning%TYPE;
    
    lc_ora_company                 gl_code_combinations.segment1%TYPE;
    
    lc_ora_cost_center             gl_code_combinations.segment2%TYPE;
    
    lc_ora_account                 gl_code_combinations.segment3%TYPE;
    
    lc_ora_location                gl_code_combinations.segment4%TYPE;
    
    lc_ora_intercompany            gl_code_combinations.segment5%TYPE;
    
    lc_ora_lob                     gl_code_combinations.segment6%TYPE;
    
    lc_ora_future                  gl_code_combinations.segment7%TYPE;
    
    lc_order_source_id_poe         oe_order_sources.order_source_id%TYPE;
    
    lc_order_source_id_pro         oe_order_sources.order_source_id%TYPE;
    
    lc_order_source_id_spc         oe_order_sources.order_source_id%TYPE;
    
    lr_ship_to_cust_location_info  hz_locations%ROWTYPE;
    
    ln_ccid                        NUMBER;
    
    lc_error_msg                   VARCHAR2(5000)                                := NULL;
    
    lr_operating_unit_info         hr_operating_units%ROWTYPE;
    
    lr_batch_source_id             ra_batch_sources_all.batch_source_id%TYPE;
    
    lr_cust_trx_type               ra_cust_trx_types_all%ROWTYPE;
    
    lr_terms                       ra_terms%ROWTYPE;
    
    lr_om_line_attribute_info      xx_om_line_attributes_all%ROWTYPE;

    lc_description                 ra_interface_lines_all.description%TYPE;
    
    lr_pos_ordt_info               xx_ar_order_receipt_dtl%ROWTYPE;
    
    lr_pos_info                    xx_ar_pos_inv_order_ref%ROWTYPE;
    
    l_credit_check_flag            VARCHAR2(2)                                    := 'N';
    
    ln_loop_counter                NUMBER                                         := 0;
    
    l_AB_flag                      VARCHAR2(2)                                    := 'N';
    
    l_inv_seq_counter              xx_ar_subscriptions.inv_seq_counter%TYPE;
    
    lr_contract_info               xx_ar_contracts%ROWTYPE;
    
    lc_store_loc                   VARCHAR2(30) := 'STORE%';

    lc_new_loc                     hr_locations_all.location_code%TYPE;

    lc_new_region                  hr_locations_all.region_1%TYPE;

    lc_new_loc_type                hr_lookups.meaning%TYPE;

    lc_segment                     gl_code_combinations.segment4%TYPE;
    
  BEGIN   

    entering_sub(p_procedure_name  => lc_procedure_name,
                 p_parameters      => lt_parameters);

    /***********************************************************************************
    * Validate we have all the information in subscriptions needed to create the invoice
    ***********************************************************************************/

    lc_action := 'Looping thru subscription array for prevalidation';

    FOR indx IN 1 .. px_subscription_array.COUNT
    LOOP

      /********************************
      * Validate we have item unit cost
      ********************************/

      IF px_subscription_array(indx).item_unit_cost IS NULL
      THEN

        lc_error := 'Missing item cost';
        RAISE le_skip;

      END IF;

      /***************************************************************
      * Validate we have not interfaced invoice information previously
      ***************************************************************/

      IF px_subscription_array(indx).invoice_interfaced_flag NOT IN ('N', 'E')
      THEN
        lc_error := 'Invoice interface flag: ' || px_subscription_array(indx).invoice_interfaced_flag;
        RAISE le_skip;
      END IF;

      /****************************************************************************
      * Validate if we need to interface tax and keep a running total of tax amount
      ****************************************************************************/

      IF p_program_setups('tax_enabled_flag') = 'Y'
      THEN
        IF px_subscription_array(indx).tax_amount > 0
        THEN
          lc_error := 'Missing tax amount';
          RAISE le_skip;
        ELSE

          /*********************************
          * Keep running total of tax amount
          **********************************/

          ln_total_tax_amount := NVL(ln_total_tax_amount, 0) + px_subscription_array(indx).tax_amount;

        END IF;
      END IF;

    END LOOP;

    lc_action := 'Setting transaction savepoint';

    SAVEPOINT sp_transaction;

    /***********************************************************************
    * Loop thru all the information in subscriptions for interfacing invoice
    ***********************************************************************/

    lc_action := 'Looping thru subscription array for interfacing invoice';

    FOR indx IN 1 .. px_subscription_array.COUNT
    LOOP
      BEGIN
      
        /******************************
        * Get contract line information
        ******************************/

        lc_action := 'Calling get_contract_line_info at populate_invoice_interface';

        get_contract_line_info(p_contract_id          => px_subscription_array(indx).contract_id,
                               p_contract_line_number => px_subscription_array(indx).contract_line_number,
                               x_contract_line_info   => lr_contract_line_info); 

        IF  px_subscription_array(indx).billing_sequence_number < lr_contract_line_info.initial_billing_sequence
        --AND lr_contract_line_info.program = 'SS'
        THEN
          
          /*****************************
          * get invoice sequence counter
          *****************************/
          IF px_subscription_array(indx).inv_seq_counter IS NULL
          THEN
            FOR indx IN 1 .. px_subscription_array.COUNT
            LOOP
              IF ln_loop_counter = 0
              THEN
                ln_loop_counter := ln_loop_counter + 1; 
                get_inv_seq_counter(p_contract_number => px_subscription_array(indx).contract_number
                                   ,x_inv_seq_counter => l_inv_seq_counter);
                                   
                px_subscription_array(indx).inv_seq_counter := l_inv_seq_counter;
                
                lc_action := 'Calling update_subscription_info';
                update_subscription_info(px_subscription_info => px_subscription_array(indx));
              ELSE
                px_subscription_array(indx).inv_seq_counter := l_inv_seq_counter;
                
                lc_action := 'Calling update_subscription_info';
                update_subscription_info(px_subscription_info => px_subscription_array(indx));
              END IF;
            END LOOP;
          END IF; 
         /**************************************
          * Get initial order header invoice info
          **************************************/

          IF (lr_invoice_header_info.customer_trx_id IS NULL)
          THEN
            lc_action := 'Calling get_invoice_header_info';

            IF p_contract_info.external_source = 'POS'
            THEN
              get_pos_ordt_info(p_order_number => p_contract_info.initial_order_number,
                                x_ordt_info    => lr_pos_ordt_info);
                    
              get_pos_info(p_header_id        => lr_pos_ordt_info.header_id,
                           p_orig_sys_doc_ref => p_contract_info.initial_order_number,
                           x_pos_info         => lr_pos_info);
                           
              get_invoice_header_info(p_invoice_number      => lr_pos_info.summary_trx_number,
                                      x_invoice_header_info => lr_invoice_header_info);
            ELSE
              get_invoice_header_info(p_invoice_number      => p_contract_info.initial_order_number,
                                      x_invoice_header_info => lr_invoice_header_info);
            END IF;
          END IF;

          px_subscription_array(indx).invoice_interfaced_flag := 'Y';
          px_subscription_array(indx).invoice_created_flag    := 'Y';
          px_subscription_array(indx).invoice_number          := lr_invoice_header_info.trx_number;
          
        ELSIF px_subscription_array(indx).billing_sequence_number >= lr_contract_line_info.initial_billing_sequence
        THEN

          /*****************************
          * get invoice sequence counter
          *****************************/
          IF px_subscription_array(indx).inv_seq_counter IS NULL
          THEN
            FOR indx IN 1 .. px_subscription_array.COUNT
            LOOP
              IF ln_loop_counter = 0
              THEN
                ln_loop_counter := ln_loop_counter + 1; 
                get_inv_seq_counter(p_contract_number => px_subscription_array(indx).contract_number
                                   ,x_inv_seq_counter => l_inv_seq_counter);
                                   
                px_subscription_array(indx).inv_seq_counter := l_inv_seq_counter;
                
                lc_action := 'Calling update_subscription_info';
                update_subscription_info(px_subscription_info => px_subscription_array(indx));
              ELSE
                px_subscription_array(indx).inv_seq_counter := l_inv_seq_counter;
                
                lc_action := 'Calling update_subscription_info';
                update_subscription_info(px_subscription_info => px_subscription_array(indx));
              END IF;
            END LOOP;
          END IF; 

          /******************************
          * Get initial order header info
          ******************************/
          /*
          BEGIN
              get_order_header_info(p_order_number      => p_contract_info.initial_order_number,
                                    x_order_header_info => lr_order_header_info);
          EXCEPTION
            WHEN OTHERS THEN
                exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => TRUE);
                RAISE_APPLICATION_ERROR(-20101, 'PROCEDURE: ' || lc_procedure_name || ' SQLCODE: ' || SQLCODE || ' SQLERRM: ' || SQLERRM);
          END;
          */

          IF (lr_order_header_info.header_id IS NULL) 
          THEN
            lc_action := 'Calling get_order_header_info';

            IF p_contract_info.external_source = 'POS'
            THEN
              get_pos_ordt_info(p_order_number => p_contract_info.initial_order_number,
                    x_ordt_info    => lr_pos_ordt_info);
                    
              get_pos_info(p_header_id        => lr_pos_ordt_info.header_id, 
                           p_orig_sys_doc_ref => p_contract_info.initial_order_number,
                           x_pos_info         => lr_pos_info);
                           
              get_order_header_info(
                                  --p_order_number      => lr_pos_info.sales_order,              --Commented for NAIT-126620
                                    p_order_number      => p_contract_info.initial_order_number, --Added for NAIT-126620
                                    x_order_header_info => lr_order_header_info);
            ELSE
              get_order_header_info(p_order_number      => p_contract_info.initial_order_number,
                                    x_order_header_info => lr_order_header_info);
            END IF;

          END IF;
          
          /*************************************************
          * Get initial order BILL_TO cust account site info
          *************************************************/

          IF (lr_bill_to_cust_acct_site_info.cust_acct_site_id IS NULL)
          THEN
            lc_action := 'Calling get_cust_account_site_info for BILL_TO';
            
            IF p_contract_info.external_source = 'POS'
            THEN
              get_customer_pos_info(p_aops           => p_contract_info.bill_to_osr,
                                    x_customer_info  => lr_customer_info);
                                  
              get_cust_site_pos_info(p_customer_id     => lr_customer_info.cust_account_id,
                                     x_cust_site_info  => lr_bill_to_cust_acct_site_info);
            ELSE
              get_cust_account_site_info(p_site_use_id            => lr_order_header_info.invoice_to_org_id,
                                         p_site_use_code          => 'BILL_TO',
                                         x_cust_account_site_info => lr_bill_to_cust_acct_site_info);
            END IF;

          END IF;          

          /**********************************
          * Get initial BILL TO cust osr info
          **********************************/

          IF (lr_bill_to_cust_site_osr_info.orig_system_reference IS NULL)
          THEN
            lc_action := 'Calling get_cust_site_osr_info for BILL_TO';
            /*IF p_contract_info.external_source = 'POS'
            THEN
              get_cust_site_osr_info(p_owner_table_name   => 'HZ_CUST_ACCT_SITES_ALL',
                                     p_orig_system        => 'RMS',
                                     p_status             => 'A',
                                     p_owner_table_id     => lr_bill_to_cust_acct_site_info.cust_acct_site_id,
                                     x_cust_site_osr_info => lr_bill_to_cust_site_osr_info);
            ELSE*/
              get_cust_site_osr_info(p_owner_table_name   => 'HZ_CUST_ACCT_SITES_ALL',
                                     p_orig_system        => 'A0',
                                     p_status             => 'A',
                                     p_owner_table_id     => lr_bill_to_cust_acct_site_info.cust_acct_site_id,
                                     x_cust_site_osr_info => lr_bill_to_cust_site_osr_info);
            --END IF;

          END IF;

          /*****************************************
          * Get item information from the master org
          *****************************************/

          lc_action := 'Calling get_item_master_info';

          get_item_master_info(p_item_name        => lr_contract_line_info.item_name,
                               x_item_master_info => lr_item_master_info);

          /**************************************
          * Get initial order header invoice info
          **************************************/

          IF (lr_invoice_header_info.customer_trx_id IS NULL)
          THEN
            lc_action := 'Calling get_invoice_header_info';

            IF p_contract_info.external_source = 'POS'
            THEN
              get_pos_ordt_info(p_order_number => p_contract_info.initial_order_number,
                                x_ordt_info    => lr_pos_ordt_info);
                    
              get_pos_info(p_header_id => lr_pos_ordt_info.header_id,
                           p_orig_sys_doc_ref => p_contract_info.initial_order_number,
                           x_pos_info  => lr_pos_info);
                           
              get_invoice_header_info(p_invoice_number      => lr_pos_info.summary_trx_number,
                                      x_invoice_header_info => lr_invoice_header_info);
            ELSE
              get_invoice_header_info(p_invoice_number      => p_contract_info.initial_order_number,
                                      x_invoice_header_info => lr_invoice_header_info);
            END IF;

          END IF;

          /*****************************
          * Get invoice line information
          *****************************/

         lc_action := 'Calling get_invoice_line_info ' || lr_invoice_header_info.customer_trx_id
                                                || ', ' || lr_contract_line_info.initial_order_line
                                                || ', ' || lr_item_master_info.inventory_item_id
                                                || ', ' || px_subscription_array(indx).contract_line_amount
                                                || ', ' || p_contract_info.external_source
          ;          
          IF lr_contract_line_info.item_name != p_program_setups('termination_sku')
          THEN 
            get_invoice_line_info(p_customer_trx_id     => lr_invoice_header_info.customer_trx_id,
                                  p_line_number         => lr_contract_line_info.initial_order_line,
                                  p_inventory_item_id   => lr_item_master_info.inventory_item_id,
                                  p_cont_line_amt       => px_subscription_array(indx).contract_line_amount,
                                  p_source              => p_contract_info.external_source,
                                  x_invoice_line_info   => lr_invoice_line_info);
          END IF;

          /*************************************
          * Get invoice distribution information
          * attribute6  -- COGS info
          * attribute11 -- sales_order info
          *************************************/

          lc_action := 'Calling get_invoice_dist_info';
          
          IF lr_contract_line_info.item_name != p_program_setups('termination_sku')
          THEN 
            get_invoice_dist_info(p_customer_trx_line_id  => lr_invoice_line_info.customer_trx_line_id,
                                  p_account_class         => 'REV',
                                  x_invoice_dist_info     => lr_invoice_dist_info);
          ELSE 
            lr_invoice_dist_info := NULL;
          END IF;

          /********************************************************
          * Get uom information for uom code in subscriptions table
          ********************************************************/

          lc_action := 'Calling get_uom_info';

          get_uom_info(p_uom_code => px_subscription_array(indx).uom_code,
                       x_uom_info => lr_uom_info);

          /**********************************************************
          * Compare primary uom with the value in subscriptions table
          **********************************************************/

          IF (px_subscription_array(indx).uom_code != lr_item_master_info.primary_uom_code)
          THEN
            lc_error := 'UOM Mismatch. Item Master: ' || lr_item_master_info.primary_uom_code || ' Subscription: ' || px_subscription_array(indx).uom_code;
            RAISE le_processing;
          END IF;

          /***********************************************************************************************************
          * Get item category info to find the item department.  Category set name: Inventory, mtl_categories.segment3
          ***********************************************************************************************************/

          lc_action := 'Calling get_item_category_info to get the department value.';

          get_item_category_info(p_inventory_item_id   => lr_item_master_info.inventory_item_id,
                                 p_organization_id     => lr_item_master_info.organization_id,
                                 p_category_set_name   => 'Inventory',
                                 x_item_category_info  => lr_item_category_info);

          /*******************************************
          * Get sales account matrix information
          *   target_value1 contains revenue account.
          *   target_value2 contains cogs
          *   target_value3 contains inventory
          *   target_value4 contains cons
          *******************************************/

          lc_action :=  'Calling get_sales_acct_matrix_info for SALES ACCOUNTING MATRIX with combination of ITEM_TYPE And DEPT';

          --Fetching Sales Account For ITEM_TYPE And DEPT Combination
          BEGIN
            lr_sales_account_matrix_info := NULL;

            lr_sales_account_matrix_info.source_value1 := NULL;
            lr_sales_account_matrix_info.source_value2 := lr_item_master_info.item_type;
            lr_sales_account_matrix_info.source_value3 := lr_item_category_info.segment3;
            
            get_sales_acct_matrix_info(p_translation_name  => 'SALES ACCOUNTING MATRIX',
                                       px_translation_info => lr_sales_account_matrix_info);
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              lr_sales_account_matrix_info := NULL;
            WHEN OTHERS THEN
              lr_sales_account_matrix_info := NULL;
          END;
          
          lc_action :=  'Calling get_sales_acct_matrix_info for SALES ACCOUNTING MATRIX with DEPT only';
          
          -- Fetching Sales Account For DEPT Alone
          IF lr_sales_account_matrix_info.target_value1 IS NULL
          THEN
          
            BEGIN
              lr_sales_account_matrix_info := NULL;
              
              lr_sales_account_matrix_info.source_value1 := NULL;
              lr_sales_account_matrix_info.source_value2 := NULL;
              lr_sales_account_matrix_info.source_value3 := lr_item_category_info.segment3;
              
              get_sales_acct_matrix_info(p_translation_name  => 'SALES ACCOUNTING MATRIX',
                                         px_translation_info => lr_sales_account_matrix_info);
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                lr_sales_account_matrix_info := NULL;
              WHEN OTHERS THEN
                lr_sales_account_matrix_info := NULL;
            END;
          
          END IF;
          
          lc_action :=  'Calling get_sales_acct_matrix_info for SALES ACCOUNTING MATRIX with ITEM_TYPE only';
          
          -- Fetching Sales Account For ITEM_TYPE Alone
          IF lr_sales_account_matrix_info.target_value1 IS NULL
          THEN

            BEGIN
              lr_sales_account_matrix_info := NULL;
              
              lr_sales_account_matrix_info.source_value1 := NULL;
              lr_sales_account_matrix_info.source_value2 := lr_item_master_info.item_type;
              lr_sales_account_matrix_info.source_value3 := NULL;
              
              get_sales_acct_matrix_info(p_translation_name  => 'SALES ACCOUNTING MATRIX',
                                         px_translation_info => lr_sales_account_matrix_info);
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                lr_sales_account_matrix_info := NULL;
              WHEN OTHERS THEN
                lr_sales_account_matrix_info := NULL;
            END;

          END IF;

          /****************************************
          * get organization_id and set_of_books_id
          ****************************************/
         
          IF lr_operating_unit_info.organization_id IS NULL
          THEN
            lc_action := 'Calling get_operating_unit_info';
         
            get_operating_unit_info(p_ord_id               => FND_PROFILE.VALUE('ORG_ID'),
                                    x_operating_unit_info  => lr_operating_unit_info);
          END IF;
          
          /***********************
          * get transaction source
          ***********************/
         
          IF lr_batch_source_id IS NULL
          THEN
            lc_action := 'Calling get_batch_source_info';
         
            get_batch_source_info(p_trx_source       => p_program_setups('transaction_source'),
                                  p_ord_id           => lr_operating_unit_info.organization_id,
                                  x_batch_source_id  => lr_batch_source_id);
          END IF;                                  
         
          /**************************
          * get cust transaction type
          **************************/
         
          IF lr_cust_trx_type.cust_trx_type_id IS NULL
          THEN
            lc_action := 'Calling get_cust_trx_type_info';
         
            get_cust_trx_type_info(p_trx_type       => p_program_setups('transaction_type'),
                                   x_cust_trx_type  => lr_cust_trx_type); 
          END IF;
  
          /*********************************
          * Get customer account information
          *********************************/

          IF (lr_customer_info.cust_account_id IS NULL) 
          THEN
          
            lc_action := 'Calling get_customer_info';

            IF p_contract_info.external_source = 'POS'
            THEN
              get_customer_pos_info(p_aops           => p_contract_info.bill_to_osr,
                                    x_customer_info  => lr_customer_info);
            ELSE
              get_customer_info(p_cust_account_id => lr_order_header_info.sold_to_org_id,
                                x_customer_info   => lr_customer_info);
            END IF;
                              
          END IF;
         
          /******************
          * get ra_terms info
          ******************/
         
          IF lr_terms.term_id IS NULL
          THEN
            lc_action := 'Calling get_term_info';
         
            IF p_contract_info.payment_type = 'AB'
            THEN
              get_term_ab_info(p_cust_acct_id => lr_customer_info.cust_account_id,
                               x_terms       => lr_terms);
            ELSE
              get_term_info(p_cust_trx_type => lr_cust_trx_type.TYPE,
                            x_terms         => lr_terms); 
            END IF;
          END IF;  
         
          /***************************************
          * Populate ra_interface_lines_all record
          ***************************************/

          IF ln_trx_number IS NULL
          THEN
              
            lc_action :=  'Getting xx_ar_trx_subscriptions_ab_s.NEXTVAL';

            ln_trx_number := xx_ar_trx_subscriptions_ab_s.NEXTVAL;
              
            IF p_contract_info.payment_type = 'AB'
            THEN

              --lc_action :=  'Getting xx_ar_trx_subscriptions_ab_s.NEXTVAL';

              --ln_trx_number := xx_ar_trx_subscriptions_ab_s.NEXTVAL;
  
              lc_description := px_subscription_array(indx).inv_seq_counter|| '-' || lr_item_master_info.description;

            ELSE
              --lc_action :=  'Getting xx_artrx_subscriptions_s.NEXTVAL';

              --ln_trx_number := xx_artrx_subscriptions_s.NEXTVAL;

              lc_description := 'Subscription Billing For Contract - ' || px_subscription_array(indx).contract_number || '-' || px_subscription_array(indx).inv_seq_counter;
 
            END IF;
          END IF;
         
          lc_action :=  'Populating ra_interface_lines_all record';

          ln_interface_line_id   := ra_customer_trx_lines_s.NEXTVAL;

          lr_ra_intf_lines_info                               := NULL;
          lr_ra_intf_lines_info.interface_line_id             := ln_interface_line_id;
          lr_ra_intf_lines_info.trx_number                    := ln_trx_number;
          lr_ra_intf_lines_info.trx_date                      := SYSDATE;
          lr_ra_intf_lines_info.batch_source_name             := p_program_setups('transaction_source');
          lr_ra_intf_lines_info.amount                        := px_subscription_array(indx).contract_line_amount;
          lr_ra_intf_lines_info.description                   := lc_description;
          lr_ra_intf_lines_info.line_type                     := 'LINE';

          lr_ra_intf_lines_info.currency_code                 := 'USD';
          lr_ra_intf_lines_info.conversion_type               := 'User';
          lr_ra_intf_lines_info.conversion_rate               := 1;
          lr_ra_intf_lines_info.conversion_date               := SYSDATE;

          lr_ra_intf_lines_info.header_attribute_category     := 'SALES_ACCT';
          lr_ra_intf_lines_info.header_attribute1             := p_contract_info.initial_order_number;
          lr_ra_intf_lines_info.header_attribute13            := lr_order_header_info.orig_sys_document_ref;
          lr_ra_intf_lines_info.header_attribute14            := lr_order_header_info.header_id;
          lr_ra_intf_lines_info.header_attribute15            := 'N';

          lr_ra_intf_lines_info.last_update_date              := SYSDATE;
          lr_ra_intf_lines_info.last_updated_by               := FND_GLOBAL.USER_ID;
          lr_ra_intf_lines_info.creation_date                 := SYSDATE;
          lr_ra_intf_lines_info.created_by                    := FND_GLOBAL.USER_ID;
          lr_ra_intf_lines_info.last_update_login             := FND_GLOBAL.USER_ID;

          lr_ra_intf_lines_info.orig_system_bill_customer_ref := lr_bill_to_cust_site_osr_info.orig_system_reference;
          lr_ra_intf_lines_info.orig_system_bill_address_ref  := lr_bill_to_cust_site_osr_info.orig_system_reference;
          lr_ra_intf_lines_info.orig_system_ship_customer_ref := lr_bill_to_cust_site_osr_info.orig_system_reference;  --??
          lr_ra_intf_lines_info.orig_system_ship_address_ref  := lr_bill_to_cust_site_osr_info.orig_system_reference;  --??

          lr_ra_intf_lines_info.gl_date                       := SYSDATE;
          lr_ra_intf_lines_info.memo_line_name                := p_program_setups('memo_line');

          lr_ra_intf_lines_info.inventory_item_id             := lr_item_master_info.inventory_item_id;
          lr_ra_intf_lines_info.interface_line_attribute6     := px_subscription_array(indx).item_unit_cost;
          lr_ra_intf_lines_info.uom_code                      := lr_uom_info.uom_code;

          lr_ra_intf_lines_info.orig_system_bill_customer_id  := lr_customer_info.cust_account_id;--lr_order_header_info.sold_to_org_id;
          lr_ra_intf_lines_info.orig_system_ship_customer_id  := lr_customer_info.cust_account_id;--lr_order_header_info.sold_to_org_id;  --??
          lr_ra_intf_lines_info.orig_system_sold_customer_id  := lr_customer_info.cust_account_id;--lr_order_header_info.sold_to_org_id;
          lr_ra_intf_lines_info.orig_system_bill_address_id   := lr_bill_to_cust_acct_site_info.cust_acct_site_id;
          lr_ra_intf_lines_info.orig_system_ship_address_id   := lr_bill_to_cust_acct_site_info.cust_acct_site_id; --??

          lr_ra_intf_lines_info.taxable_flag                  := 'N';

          lr_ra_intf_lines_info.line_number                   := px_subscription_array(indx).contract_line_number;

          lr_ra_intf_lines_info.quantity                      := lr_contract_line_info.quantity;
          lr_ra_intf_lines_info.unit_selling_price            := px_subscription_array(indx).contract_line_amount;
          
          lr_ra_intf_lines_info.unit_standard_price           := px_subscription_array(indx).item_unit_cost;

          lr_ra_intf_lines_info.interface_line_context        := 'RECURRING BILLING';
          lr_ra_intf_lines_info.interface_line_attribute1     := p_contract_info.initial_order_number || '-' || px_subscription_array(indx).inv_seq_counter;
          lr_ra_intf_lines_info.interface_line_attribute2     := p_contract_info.contract_major_version;
          lr_ra_intf_lines_info.interface_line_attribute3     := px_subscription_array(indx).contract_line_number;
          lr_ra_intf_lines_info.interface_line_attribute4     := px_subscription_array(indx).billing_sequence_number;
          lr_ra_intf_lines_info.interface_line_attribute5     := px_subscription_array(indx).contract_number;
 
          lr_ra_intf_lines_info.interface_line_attribute11    := '0';

          lr_ra_intf_lines_info.warehouse_id                  := lr_item_master_info.organization_id;
          
          lr_ra_intf_lines_info.term_id                       := lr_terms.term_id;
          lr_ra_intf_lines_info.term_name                     := lr_terms.name;
          lr_ra_intf_lines_info.org_id                        := lr_operating_unit_info.organization_id;
          lr_ra_intf_lines_info.cust_trx_type_name            := lr_cust_trx_type.name;
          lr_ra_intf_lines_info.cust_trx_type_id              := lr_cust_trx_type.cust_trx_type_id;
          lr_ra_intf_lines_info.set_of_books_id               := lr_operating_unit_info.set_of_books_id;
          
          lr_ra_intf_lines_info.translated_description        := lr_item_master_info.segment1;
          
          lr_ra_intf_lines_info.purchase_order                := lr_contract_line_info.purchase_order;

          lc_action :=  'Calling insert_ra_interface_lines_all';

          insert_ra_interface_lines_all(p_ra_interface_lines_all_info => lr_ra_intf_lines_info);

          /************************************************
          * Populate ra_interface_distributions_all record
          ************************************************/
          
          /********************************
          * Get order header attribute info
          ********************************/

          IF (lr_om_hdr_attribute_info.header_id IS NULL)
          THEN
            lc_action := 'Calling get_om_hdr_attribute_info order_header: ' || lr_order_header_info.header_id || ', ' || lr_order_header_info.header_id;

            get_om_hdr_attribute_info(p_header_id             => lr_order_header_info.header_id,
                                      x_om_hdr_attribute_info => lr_om_hdr_attribute_info);

          END IF;

          /********************
          * Get order line info
          ********************/

          lc_action := 'Calling get_order_line_info';
          
          IF lr_contract_line_info.item_name != p_program_setups('termination_sku')
          THEN        

            get_order_line_info(p_header_id       => lr_order_header_info.header_id,
                                p_line_number     => lr_contract_line_info.initial_order_line,
                                x_order_line_info => lr_order_line_info);
          END IF;

          /********************
          * Get order line info
          ********************/

          lc_action := 'Calling get_om_line_attribute_info line_id: ' || lr_order_line_info.line_id;

          IF lr_contract_line_info.item_name != p_program_setups('termination_sku')
          THEN
            get_om_line_attribute_info(p_line_id                => lr_order_line_info.line_id,
                                       x_om_line_attribute_info => lr_om_line_attribute_info); 
            
            IF lr_om_line_attribute_info.consignment_bank_code IS NULL 
            THEN
              lr_sales_account_matrix_info.target_value4 := '';
            END IF;
          
          ELSE
            lr_sales_account_matrix_info.target_value4 := '';
          END IF;

          /***********************************************************
          * Get location info for accounting based on ship_from_org_id
          ***********************************************************/

          lc_action := 'Calling get_location_info for line level';

          get_location_info(p_org_id    => lr_order_header_info.ship_from_org_id,--lr_order_line_info.ship_from_org_id,
                            x_loc_code  => lc_sloc,
                            x_region    => lc_ship_from_state,
                            x_loc_type  => lc_sloc_type);

          /**************************************************************
          * Get location info for accounting based on created_by_store_id
          **************************************************************/

          IF (lc_oloc IS NULL OR lc_oloc_type IS NULL)
          THEN
            lc_action := 'Calling get_location_info for order level';

            get_location_info(p_org_id    => lr_om_hdr_attribute_info.created_by_store_id,
                              x_loc_code  => lc_oloc,
                              x_region    => lc_region,
                              x_loc_type  => lc_oloc_type);

          END IF;

          /***********************************************
          * Get location info for accounting based on CCID
          ***********************************************/
          lc_action := 'Calling get_acct_segment_info';
          
          get_acct_segment_info(p_ccid_id  => lr_invoice_dist_info.code_combination_id,
                                x_segment  => lc_segment);

          /******************************
          * checking store closure status
          ******************************/
          lc_action := 'Calling get_store_close_info';
          
          get_store_close_info(p_store_number     => lc_segment,
                               x_store_info       => gc_store_number);
          
          IF lc_segment != gc_store_number
          THEN
            /*******************************************************************************
            * Updating contracts table with new store# against store closed on initial order
            *******************************************************************************/
            UPDATE xx_ar_contracts
            set    store_number       = gc_store_number
                  ,store_close_flag   = 'Y'
                  ,last_update_date   = SYSDATE
                  ,last_updated_by    = NVL(FND_GLOBAL.USER_ID, -1)
                  ,last_update_login  = NVL(FND_GLOBAL.USER_ID, -1)
            WHERE  contract_id        = p_contract_info.contract_id;
            COMMIT;
            ELSE
            /******************************************************
            * Updating contracts table with store# on initial order
            ******************************************************/
            --Begin : Added NAIT-112423 || NAIT-101932 - Recurring Shred Orders - Sales Location Discrepancy between Service Contract and Sales Detail
            UPDATE xx_ar_contracts
            set    store_number       = lc_segment
                  ,last_update_date   = SYSDATE
                  ,last_updated_by    = NVL(FND_GLOBAL.USER_ID, -1)
                  ,last_update_login  = NVL(FND_GLOBAL.USER_ID, -1)
            WHERE  contract_id        = p_contract_info.contract_id;
            COMMIT;  
            --END : for NAIT-112423 || NAIT-101932
          END IF;
            
          /**************************************
          * Get contract header level information
          **************************************/
          
          lc_action := 'Calling get_contract_info';
          
          get_contract_info(p_contract_id     => p_contract_info.contract_id,
                            x_contract_info   => lr_contract_info);
                            
          IF lr_contract_info.store_close_flag = 'Y'
          THEN
            get_new_location_info(p_store_number    => lr_contract_info.store_number,
                                  x_loc_code        => lc_new_loc,
                                  x_region          => lc_new_region,
                                  x_loc_type        => lc_new_loc_type);
            
            IF NVL(lc_oloc_type,1) LIKE lc_store_loc AND lc_sloc_type LIKE lc_store_loc 
            THEN
              lc_oloc      := lc_new_loc;
              lc_oloc_type := lc_new_loc_type;
            ELSIF NVL(lc_oloc_type,1) LIKE lc_store_loc AND lc_sloc_type NOT LIKE lc_store_loc 
            THEN
              lc_oloc      := lc_new_loc;
              lc_oloc_type := lc_new_loc_type;
            ELSIF NVL(lc_oloc_type,1) NOT LIKE lc_store_loc AND lc_sloc_type LIKE lc_store_loc 
            THEN
              lc_sloc      := lc_new_loc;
              lc_sloc_type := lc_new_loc_type;
            ELSIF NVL(lc_oloc_type,1) NOT LIKE lc_store_loc AND lc_sloc_type NOT LIKE lc_store_loc 
            THEN
              lc_sloc      := lc_new_loc;
              lc_sloc_type := lc_new_loc_type;
            END IF;

          END IF;
          
          /*********************************
          * Get customer account information
          *********************************/

          IF (lr_customer_info.cust_account_id IS NULL) 
          THEN
          
            lc_action := 'Calling get_customer_info';

            IF p_contract_info.external_source = 'POS'
            THEN
              get_customer_pos_info(p_aops           => p_contract_info.bill_to_osr,
                                    x_customer_info  => lr_customer_info);
            ELSE
              get_customer_info(p_cust_account_id => lr_order_header_info.sold_to_org_id,
                                x_customer_info   => lr_customer_info);
            END IF;
                              
          END IF;

          
          lc_action := 'callling xx_ar_create_acct_child_pkg.xx_get_gl_coa for accounting';
          
          xx_ar_create_acct_child_pkg.xx_get_gl_coa(
                             p_oloc           => lc_oloc
                            ,p_sloc           => lc_sloc
                            ,p_oloc_type      => lc_oloc_type
                            ,p_sloc_type      => lc_sloc_type
                            ,p_line_id        => NULL
                            ,p_rev_account    => lr_sales_account_matrix_info.target_value1
                            ,p_acc_class      => 'REV'
                            ,p_cust_type      => lr_customer_info.attribute18
                            ,p_trx_type       => NULL
                            ,p_log_flag       => NULL
                            ,p_tax_state      => NULL
                            ,p_tax_loc        => NULL 
                            ,p_description    => NULL
                            ,x_company        => lc_ora_company
                            ,x_costcenter     => lc_ora_cost_center
                            ,x_account        => lc_ora_account
                            ,x_location       => lc_ora_location
                            ,x_intercompany   => lc_ora_intercompany
                            ,x_lob            => lc_ora_lob
                            ,x_future         => lc_ora_future
                            ,x_ccid           => ln_ccid
                            ,x_error_message  => lc_error_msg
                            );
          
          lc_action := 'populating ra_interface_distributions_all';
          
          lr_ra_intf_dists_info                                 := NULL;
          lr_ra_intf_dists_info.interface_distribution_id       := NULL;
          lr_ra_intf_dists_info.interface_line_id               := ln_interface_line_id;
          lr_ra_intf_dists_info.interface_line_context          := 'RECURRING BILLING';
          lr_ra_intf_dists_info.interface_line_attribute1       := p_contract_info.initial_order_number || '-' || px_subscription_array(indx).inv_seq_counter;
          lr_ra_intf_dists_info.interface_line_attribute2       := p_contract_info.contract_major_version;
          lr_ra_intf_dists_info.interface_line_attribute3       := px_subscription_array(indx).contract_line_number;
          lr_ra_intf_dists_info.interface_line_attribute4       := px_subscription_array(indx).billing_sequence_number;
          lr_ra_intf_dists_info.interface_line_attribute5       := px_subscription_array(indx).contract_number;
          lr_ra_intf_dists_info.interface_line_attribute6       := NULL;
          lr_ra_intf_dists_info.interface_line_attribute7       := NULL;
          lr_ra_intf_dists_info.interface_line_attribute8       := NULL;
          lr_ra_intf_dists_info.account_class                   := 'REV';
          lr_ra_intf_dists_info.amount                          := NULL;
          lr_ra_intf_dists_info.percent                         := 100;
          lr_ra_intf_dists_info.interface_status                := NULL;
          lr_ra_intf_dists_info.request_id                      := NULL;
          lr_ra_intf_dists_info.code_combination_id             := ln_ccid;
          lr_ra_intf_dists_info.segment1                        := lc_ora_company;
          lr_ra_intf_dists_info.segment2                        := lc_ora_cost_center;
          lr_ra_intf_dists_info.segment3                        := lc_ora_account;
          lr_ra_intf_dists_info.segment4                        := lc_ora_location;
          lr_ra_intf_dists_info.segment5                        := lc_ora_intercompany;
          lr_ra_intf_dists_info.segment6                        := lc_ora_lob;
          lr_ra_intf_dists_info.segment7                        := lc_ora_future;
          lr_ra_intf_dists_info.segment8                        := NULL;
          lr_ra_intf_dists_info.segment9                        := NULL;
          lr_ra_intf_dists_info.segment10                       := NULL;
          lr_ra_intf_dists_info.segment11                       := NULL;
          lr_ra_intf_dists_info.segment12                       := NULL;
          lr_ra_intf_dists_info.segment13                       := NULL;
          lr_ra_intf_dists_info.segment14                       := NULL;
          lr_ra_intf_dists_info.segment15                       := NULL;
          lr_ra_intf_dists_info.segment16                       := NULL;
          lr_ra_intf_dists_info.segment17                       := NULL;
          lr_ra_intf_dists_info.segment18                       := NULL;
          lr_ra_intf_dists_info.segment19                       := NULL;
          lr_ra_intf_dists_info.segment20                       := NULL;
          lr_ra_intf_dists_info.segment21                       := NULL;
          lr_ra_intf_dists_info.segment22                       := NULL;
          lr_ra_intf_dists_info.segment23                       := NULL;
          lr_ra_intf_dists_info.segment24                       := NULL;
          lr_ra_intf_dists_info.segment25                       := NULL;
          lr_ra_intf_dists_info.segment26                       := NULL;
          lr_ra_intf_dists_info.segment27                       := NULL;
          lr_ra_intf_dists_info.segment28                       := NULL;
          lr_ra_intf_dists_info.segment29                       := NULL;
          lr_ra_intf_dists_info.segment30                       := NULL;
          lr_ra_intf_dists_info.comments                        := NULL;
          lr_ra_intf_dists_info.attribute_category              := 'SALES_ACCT';
          lr_ra_intf_dists_info.attribute1                      := NULL;
          lr_ra_intf_dists_info.attribute2                      := NULL;
          lr_ra_intf_dists_info.attribute3                      := NULL;
          lr_ra_intf_dists_info.attribute4                      := NULL;
          lr_ra_intf_dists_info.attribute5                      := NULL;
          lr_ra_intf_dists_info.attribute6                      := lr_invoice_dist_info.attribute6;
          lr_ra_intf_dists_info.attribute7                      := lr_sales_account_matrix_info.target_value2;
          lr_ra_intf_dists_info.attribute8                      := lr_sales_account_matrix_info.target_value3;
          lr_ra_intf_dists_info.attribute9                      := px_subscription_array(indx).item_unit_cost;
          lr_ra_intf_dists_info.attribute10                     := lr_sales_account_matrix_info.target_value4;
          lr_ra_intf_dists_info.attribute11                     := lr_invoice_dist_info.attribute11;
          lr_ra_intf_dists_info.attribute12                     := NULL;
          lr_ra_intf_dists_info.attribute13                     := NULL;
          lr_ra_intf_dists_info.attribute14                     := NULL;
          lr_ra_intf_dists_info.attribute15                     := NULL;
          lr_ra_intf_dists_info.acctd_amount                    := NULL;
          lr_ra_intf_dists_info.interface_line_attribute10      := NULL;
          lr_ra_intf_dists_info.interface_line_attribute11      := NULL;
          lr_ra_intf_dists_info.interface_line_attribute12      := NULL;
          lr_ra_intf_dists_info.interface_line_attribute13      := NULL;
          lr_ra_intf_dists_info.interface_line_attribute14      := NULL;
          lr_ra_intf_dists_info.interface_line_attribute15      := NULL;
          lr_ra_intf_dists_info.interface_line_attribute9       := NULL;
          lr_ra_intf_dists_info.created_by                      := FND_GLOBAL.USER_ID;
          lr_ra_intf_dists_info.creation_date                   := SYSDATE;
          lr_ra_intf_dists_info.last_updated_by                 := FND_GLOBAL.USER_ID;
          lr_ra_intf_dists_info.last_update_date                := SYSDATE;
          lr_ra_intf_dists_info.last_update_login               := FND_GLOBAL.USER_ID;
          lr_ra_intf_dists_info.org_id                          := FND_PROFILE.VALUE('ORG_ID');
          lr_ra_intf_dists_info.interim_tax_ccid                := NULL;
          lr_ra_intf_dists_info.interim_tax_segment1            := NULL;
          lr_ra_intf_dists_info.interim_tax_segment2            := NULL;
          lr_ra_intf_dists_info.interim_tax_segment3            := NULL;
          lr_ra_intf_dists_info.interim_tax_segment4            := NULL;
          lr_ra_intf_dists_info.interim_tax_segment5            := NULL;
          lr_ra_intf_dists_info.interim_tax_segment6            := NULL;
          lr_ra_intf_dists_info.interim_tax_segment7            := NULL;
          lr_ra_intf_dists_info.interim_tax_segment8            := NULL;
          lr_ra_intf_dists_info.interim_tax_segment9            := NULL;
          lr_ra_intf_dists_info.interim_tax_segment10           := NULL;
          lr_ra_intf_dists_info.interim_tax_segment11           := NULL;
          lr_ra_intf_dists_info.interim_tax_segment12           := NULL;
          lr_ra_intf_dists_info.interim_tax_segment13           := NULL;
          lr_ra_intf_dists_info.interim_tax_segment14           := NULL;
          lr_ra_intf_dists_info.interim_tax_segment15           := NULL;
          lr_ra_intf_dists_info.interim_tax_segment16           := NULL;
          lr_ra_intf_dists_info.interim_tax_segment17           := NULL;
          lr_ra_intf_dists_info.interim_tax_segment18           := NULL;
          lr_ra_intf_dists_info.interim_tax_segment19           := NULL;
          lr_ra_intf_dists_info.interim_tax_segment20           := NULL;
          lr_ra_intf_dists_info.interim_tax_segment21           := NULL;
          lr_ra_intf_dists_info.interim_tax_segment22           := NULL;
          lr_ra_intf_dists_info.interim_tax_segment23           := NULL;
          lr_ra_intf_dists_info.interim_tax_segment24           := NULL;
          lr_ra_intf_dists_info.interim_tax_segment25           := NULL;
          lr_ra_intf_dists_info.interim_tax_segment26           := NULL;
          lr_ra_intf_dists_info.interim_tax_segment27           := NULL;
          lr_ra_intf_dists_info.interim_tax_segment28           := NULL;
          lr_ra_intf_dists_info.interim_tax_segment29           := NULL;
          lr_ra_intf_dists_info.interim_tax_segment30           := NULL;
          lr_ra_intf_dists_info.global_attribute1               := NULL;
          lr_ra_intf_dists_info.global_attribute2               := NULL;
          lr_ra_intf_dists_info.global_attribute3               := NULL;
          lr_ra_intf_dists_info.global_attribute4               := NULL;
          lr_ra_intf_dists_info.global_attribute5               := NULL;
          lr_ra_intf_dists_info.global_attribute6               := NULL;
          lr_ra_intf_dists_info.global_attribute7               := NULL;
          lr_ra_intf_dists_info.global_attribute8               := NULL;
          lr_ra_intf_dists_info.global_attribute9               := NULL;
          lr_ra_intf_dists_info.global_attribute10              := NULL;
          lr_ra_intf_dists_info.global_attribute11              := NULL;
          lr_ra_intf_dists_info.global_attribute12              := NULL;
          lr_ra_intf_dists_info.global_attribute13              := NULL;
          lr_ra_intf_dists_info.global_attribute14              := NULL;
          lr_ra_intf_dists_info.global_attribute15              := NULL;
          lr_ra_intf_dists_info.global_attribute16              := NULL;
          lr_ra_intf_dists_info.global_attribute17              := NULL;
          lr_ra_intf_dists_info.global_attribute18              := NULL;
          lr_ra_intf_dists_info.global_attribute19              := NULL;
          lr_ra_intf_dists_info.global_attribute20              := NULL;
          lr_ra_intf_dists_info.global_attribute21              := NULL;
          lr_ra_intf_dists_info.global_attribute22              := NULL;
          lr_ra_intf_dists_info.global_attribute23              := NULL;
          lr_ra_intf_dists_info.global_attribute24              := NULL;
          lr_ra_intf_dists_info.global_attribute25              := NULL;
          lr_ra_intf_dists_info.global_attribute26              := NULL;
          lr_ra_intf_dists_info.global_attribute27              := NULL;
          lr_ra_intf_dists_info.global_attribute28              := NULL;
          lr_ra_intf_dists_info.global_attribute29              := NULL;
          lr_ra_intf_dists_info.global_attribute30              := NULL;
          lr_ra_intf_dists_info.global_attribute_category       := NULL;

          lc_action :=  'Calling insert_ra_interface_dists_all';

          insert_ra_interface_dists_all(p_ra_interface_dists_all_info => lr_ra_intf_dists_info);
          
          --px_subscription_array(indx).invoice_interfaced_flag := 'P';
          px_subscription_array(indx).invoice_number          := ln_trx_number;
 
          --End of Populate ra_interface_distributions_all

          IF (lb_tax_interfaced_flag = FALSE AND NVL(ln_total_tax_amount, 0) > 0)
          THEN

            lb_tax_interfaced_flag := TRUE;


            lc_action :=  'Populating ra_interface_lines_all tax record';

            lr_ra_intf_lines_info                               := NULL;
            lr_ra_intf_lines_info.link_to_line_id               := ln_interface_line_id;
            lr_ra_intf_lines_info.interface_line_id             := ra_customer_trx_lines_s.NEXTVAL;
            lr_ra_intf_lines_info.trx_date                      := SYSDATE;
            lr_ra_intf_lines_info.batch_source_name             := p_program_setups('transaction_source');
            lr_ra_intf_lines_info.amount                        := ln_total_tax_amount;
            lr_ra_intf_lines_info.description                   := lc_description;
            lr_ra_intf_lines_info.line_type                     := 'TAX';

            lr_ra_intf_lines_info.currency_code                 := 'USD';
            lr_ra_intf_lines_info.conversion_type               := 'User';
            lr_ra_intf_lines_info.conversion_rate               := 1;
            lr_ra_intf_lines_info.conversion_date               := SYSDATE;

            lr_ra_intf_lines_info.last_update_date              := SYSDATE;
            lr_ra_intf_lines_info.last_updated_by               := FND_GLOBAL.USER_ID;
            lr_ra_intf_lines_info.creation_date                 := SYSDATE;
            lr_ra_intf_lines_info.created_by                    := FND_GLOBAL.USER_ID;
            lr_ra_intf_lines_info.last_update_login             := FND_GLOBAL.USER_ID;

            lr_ra_intf_lines_info.gl_date                       := SYSDATE;
            lr_ra_intf_lines_info.memo_line_name                := p_program_setups('memo_line');

            lr_ra_intf_lines_info.orig_system_bill_customer_ref := lr_bill_to_cust_site_osr_info.orig_system_reference;
            lr_ra_intf_lines_info.orig_system_bill_address_ref  := lr_bill_to_cust_site_osr_info.orig_system_reference;
            lr_ra_intf_lines_info.orig_system_ship_customer_ref := lr_bill_to_cust_site_osr_info.orig_system_reference;  --??
            lr_ra_intf_lines_info.orig_system_ship_address_ref  := lr_bill_to_cust_site_osr_info.orig_system_reference;  --??

            lr_ra_intf_lines_info.header_attribute_category     := 'SALES_ACCT';
            lr_ra_intf_lines_info.header_attribute1             := p_contract_info.initial_order_number;

            lr_ra_intf_lines_info.orig_system_bill_customer_id  := lr_customer_info.cust_account_id;--lr_order_header_info.sold_to_org_id;
            lr_ra_intf_lines_info.orig_system_ship_customer_id  := lr_customer_info.cust_account_id;--lr_order_header_info.sold_to_org_id;  --??
            lr_ra_intf_lines_info.orig_system_sold_customer_id  := lr_customer_info.cust_account_id;--lr_order_header_info.sold_to_org_id;
            lr_ra_intf_lines_info.orig_system_bill_address_id   := lr_bill_to_cust_acct_site_info.cust_acct_site_id;
            lr_ra_intf_lines_info.orig_system_ship_address_id   := lr_bill_to_cust_acct_site_info.cust_acct_site_id; --??

            lr_ra_intf_lines_info.interface_line_context        := 'RECURRING BILLING';
            lr_ra_intf_lines_info.interface_line_attribute1     := p_contract_info.initial_order_number || '-' || px_subscription_array(indx).inv_seq_counter || '-TAX';
            lr_ra_intf_lines_info.interface_line_attribute2     := p_contract_info.contract_major_version || '-TAX';
            lr_ra_intf_lines_info.interface_line_attribute3     := px_subscription_array(indx).contract_line_number || '-TAX';
            lr_ra_intf_lines_info.interface_line_attribute4     := px_subscription_array(indx).billing_sequence_number || '-TAX';
            lr_ra_intf_lines_info.interface_line_attribute5     := px_subscription_array(indx).contract_number || '-TAX';

            lr_ra_intf_lines_info.interface_line_attribute11    := '0';

            lr_ra_intf_lines_info.link_to_line_context          := 'RECURRING BILLING';
            lr_ra_intf_lines_info.link_to_line_attribute1       := p_contract_info.initial_order_number || '-' || px_subscription_array(indx).billing_sequence_number;
            lr_ra_intf_lines_info.link_to_line_attribute2       := p_contract_info.contract_major_version;
            lr_ra_intf_lines_info.link_to_line_attribute3       := px_subscription_array(indx).contract_line_number;
            lr_ra_intf_lines_info.link_to_line_attribute4       := px_subscription_array(indx).billing_sequence_number;
            lr_ra_intf_lines_info.link_to_line_attribute5       := px_subscription_array(indx).contract_number;

            lr_ra_intf_lines_info.tax_code                      := 'SALES';
            lr_ra_intf_lines_info.tax_rate_code                 := 'SALES';
            
            lr_ra_intf_lines_info.term_id                       := lr_terms.term_id;
            lr_ra_intf_lines_info.term_name                     := lr_terms.name;
            lr_ra_intf_lines_info.org_id                        := lr_operating_unit_info.organization_id;
            lr_ra_intf_lines_info.cust_trx_type_name            := lr_cust_trx_type.name;
            lr_ra_intf_lines_info.cust_trx_type_id              := lr_cust_trx_type.cust_trx_type_id;
            lr_ra_intf_lines_info.set_of_books_id               := lr_operating_unit_info.set_of_books_id;
            
            lr_ra_intf_lines_info.translated_description        := lr_item_master_info.segment1;
            
            lr_ra_intf_lines_info.purchase_order                := lr_contract_line_info.purchase_order;

            lc_action :=  'Calling insert_ra_interface_lines_all for tax';

            insert_ra_interface_lines_all(p_ra_interface_lines_all_info => lr_ra_intf_lines_info);

            /************************************************
            * Populate ra_interface_distributions_all record
            ************************************************/
                       
            /*************************************************
            * Get initial order SHIP TO cust account site info
            *************************************************/
         
            IF (lr_ship_to_cust_acct_site_info.cust_acct_site_id IS NULL)
            THEN
              lc_action := 'Calling get_cust_account_site_info for SHIP_TO';
         
              IF p_contract_info.external_source = 'POS'
              THEN
                get_customer_pos_info(p_aops           => p_contract_info.bill_to_osr,
                                      x_customer_info  => lr_customer_info);
                                    
                get_cust_site_pos_info(p_customer_id     => lr_customer_info.cust_account_id,
                                       x_cust_site_info  => lr_ship_to_cust_acct_site_info);
              ELSE
                get_cust_account_site_info(p_site_use_id            => lr_order_header_info.ship_to_org_id,
                                           p_site_use_code          => 'SHIP_TO',
                                           x_cust_account_site_info => lr_ship_to_cust_acct_site_info);
              END IF;
         
            END IF;
            
            /***********************************
            * Get initial order SHIP_TO location
            ***********************************/
         
              lc_action := 'Calling get_cust_location_info for SHIP_TO';
         
              get_cust_location_info(p_cust_acct_site_id  => lr_ship_to_cust_acct_site_info.cust_acct_site_id,
                                     x_cust_location_info => lr_ship_to_cust_location_info);
            
            /***********************************************************
            * Get location info for accounting based on ship_from_org_id
            ***********************************************************/
          
            IF (lc_order_source_id_poe IS NULL OR lc_order_source_id_pro IS NULL OR lc_order_source_id_spc IS NULL)
            THEN
              
              lc_action := 'Calling get_order_source_id_info';
          
              IF p_program_setups('order_source_id_poe') IS NOT NULL
              THEN
                get_order_source_id_info(p_order_name      => p_program_setups('order_source_id_poe'),
                                         x_order_source_id => lc_order_source_id_poe);
              ELSIF p_program_setups('order_source_id_pro') IS NOT NULL
              THEN
                get_order_source_id_info(p_order_name      => p_program_setups('order_source_id_pro'),
                                         x_order_source_id => lc_order_source_id_pro);
              ELSIF gc_order_source_spc IS NOT NULL  
              THEN
                get_order_source_id_info(p_order_name      => gc_order_source_spc,
                                         x_order_source_id => lc_order_source_id_spc);
              END IF;
          
            END IF;
            
            lc_action := 'Fetching tax state';
            
            IF lr_om_hdr_attribute_info.od_order_type = 'X' AND lr_ship_to_cust_location_info.country = 'US'
            THEN
                
                lc_tax_state := lr_ship_to_cust_location_info.state;
                
            ELSIF lr_om_hdr_attribute_info.od_order_type = 'X' AND lr_ship_to_cust_location_info.country = 'CA'
            THEN
                
                lc_tax_state := lr_ship_to_cust_location_info.province;
                
            ELSIF lr_om_hdr_attribute_info.delivery_code = 'P'
                  OR lr_order_header_info.order_source_id IN(lc_order_source_id_poe, lc_order_source_id_spc, lc_order_source_id_pro)
            THEN
            
                lc_tax_state := lc_ship_from_state;
                
            ELSE
                lc_tax_state := lr_om_hdr_attribute_info.ship_to_state;
            END IF;
          
            IF lc_tax_state IS NOT NULL
            THEN
            
              /********************************
              * Get order header attribute info
              ********************************/
       
              IF (lc_tax_loc IS NULL)
              THEN
              
                lc_action := 'Calling get_tax_location_info';
       
                get_tax_location_info(p_tax_state  => lc_tax_state,
                                      x_tax_loc    => lc_tax_loc);
       
              END IF;
       
            END IF;
            
            lc_action := 'callling xx_ar_create_acct_child_pkg.xx_get_gl_coa for accounting';
            
            xx_ar_create_acct_child_pkg.xx_get_gl_coa(
                               p_oloc           => lc_oloc
                              ,p_sloc           => lc_sloc
                              ,p_oloc_type      => lc_oloc_type
                              ,p_sloc_type      => lc_sloc_type
                              ,p_line_id        => NULL
                              ,p_rev_account    => lr_sales_account_matrix_info.target_value1
                              ,p_acc_class      => 'TAX'
                              ,p_cust_type      => lr_customer_info.attribute18
                              ,p_trx_type       => NULL
                              ,p_log_flag       => NULL
                              ,p_tax_state      => lc_tax_state
                              ,p_tax_loc        => lc_tax_loc 
                              ,p_description    => NULL
                              ,x_company        => lc_ora_company
                              ,x_costcenter     => lc_ora_cost_center
                              ,x_account        => lc_ora_account
                              ,x_location       => lc_ora_location
                              ,x_intercompany   => lc_ora_intercompany
                              ,x_lob            => lc_ora_lob
                              ,x_future         => lc_ora_future
                              ,x_ccid           => ln_ccid
                              ,x_error_message  => lc_error_msg
                              );
            
            lc_action := 'populating ra_interface_distributions_all for tax record';
            
            lr_ra_intf_dists_info                                 := NULL;
            lr_ra_intf_dists_info.interface_distribution_id       := NULL;
            lr_ra_intf_dists_info.interface_line_id               := ln_interface_line_id;
            lr_ra_intf_dists_info.interface_line_context          := 'RECURRING BILLING';
            lr_ra_intf_dists_info.interface_line_attribute1       := p_contract_info.initial_order_number || '-' || px_subscription_array(indx).inv_seq_counter || '-TAX';
            lr_ra_intf_dists_info.interface_line_attribute2       := p_contract_info.contract_major_version || '-TAX';
            lr_ra_intf_dists_info.interface_line_attribute3       := px_subscription_array(indx).contract_line_number || '-TAX';
            lr_ra_intf_dists_info.interface_line_attribute4       := px_subscription_array(indx).billing_sequence_number || '-TAX';
            lr_ra_intf_dists_info.interface_line_attribute5       := px_subscription_array(indx).contract_number || '-TAX';
            lr_ra_intf_dists_info.interface_line_attribute6       := NULL;
            lr_ra_intf_dists_info.interface_line_attribute7       := NULL;
            lr_ra_intf_dists_info.interface_line_attribute8       := NULL;
            lr_ra_intf_dists_info.account_class                   := 'TAX';
            lr_ra_intf_dists_info.amount                          := NULL;
            lr_ra_intf_dists_info.percent                         := 100;
            lr_ra_intf_dists_info.interface_status                := NULL;
            lr_ra_intf_dists_info.request_id                      := NULL;
            lr_ra_intf_dists_info.code_combination_id             := ln_ccid;
            lr_ra_intf_dists_info.segment1                        := lc_ora_company;
            lr_ra_intf_dists_info.segment2                        := lc_ora_cost_center;
            lr_ra_intf_dists_info.segment3                        := lc_ora_account;
            lr_ra_intf_dists_info.segment4                        := lc_ora_location;
            lr_ra_intf_dists_info.segment5                        := lc_ora_intercompany;
            lr_ra_intf_dists_info.segment6                        := lc_ora_lob;
            lr_ra_intf_dists_info.segment7                        := lc_ora_future;
            lr_ra_intf_dists_info.segment8                        := NULL;
            lr_ra_intf_dists_info.segment9                        := NULL;
            lr_ra_intf_dists_info.segment10                       := NULL;
            lr_ra_intf_dists_info.segment11                       := NULL;
            lr_ra_intf_dists_info.segment12                       := NULL;
            lr_ra_intf_dists_info.segment13                       := NULL;
            lr_ra_intf_dists_info.segment14                       := NULL;
            lr_ra_intf_dists_info.segment15                       := NULL;
            lr_ra_intf_dists_info.segment16                       := NULL;
            lr_ra_intf_dists_info.segment17                       := NULL;
            lr_ra_intf_dists_info.segment18                       := NULL;
            lr_ra_intf_dists_info.segment19                       := NULL;
            lr_ra_intf_dists_info.segment20                       := NULL;
            lr_ra_intf_dists_info.segment21                       := NULL;
            lr_ra_intf_dists_info.segment22                       := NULL;
            lr_ra_intf_dists_info.segment23                       := NULL;
            lr_ra_intf_dists_info.segment24                       := NULL;
            lr_ra_intf_dists_info.segment25                       := NULL;
            lr_ra_intf_dists_info.segment26                       := NULL;
            lr_ra_intf_dists_info.segment27                       := NULL;
            lr_ra_intf_dists_info.segment28                       := NULL;
            lr_ra_intf_dists_info.segment29                       := NULL;
            lr_ra_intf_dists_info.segment30                       := NULL;
            lr_ra_intf_dists_info.comments                        := NULL;
            lr_ra_intf_dists_info.attribute_category              := 'SALES_ACCT';
            lr_ra_intf_dists_info.attribute1                      := NULL;
            lr_ra_intf_dists_info.attribute2                      := NULL;
            lr_ra_intf_dists_info.attribute3                      := NULL;
            lr_ra_intf_dists_info.attribute4                      := NULL;
            lr_ra_intf_dists_info.attribute5                      := NULL;
            lr_ra_intf_dists_info.attribute6                      := lr_invoice_dist_info.attribute6;
            lr_ra_intf_dists_info.attribute7                      := lr_sales_account_matrix_info.target_value2;
            lr_ra_intf_dists_info.attribute8                      := lr_sales_account_matrix_info.target_value3;
            lr_ra_intf_dists_info.attribute9                      := px_subscription_array(indx).item_unit_cost;
            lr_ra_intf_dists_info.attribute10                     := lr_sales_account_matrix_info.target_value4;
            lr_ra_intf_dists_info.attribute11                     := lr_invoice_dist_info.attribute11;
            lr_ra_intf_dists_info.attribute12                     := NULL;
            lr_ra_intf_dists_info.attribute13                     := NULL;
            lr_ra_intf_dists_info.attribute14                     := NULL;
            lr_ra_intf_dists_info.attribute15                     := NULL;
            lr_ra_intf_dists_info.acctd_amount                    := NULL;
            lr_ra_intf_dists_info.interface_line_attribute10      := NULL;
            lr_ra_intf_dists_info.interface_line_attribute11      := NULL;
            lr_ra_intf_dists_info.interface_line_attribute12      := NULL;
            lr_ra_intf_dists_info.interface_line_attribute13      := NULL;
            lr_ra_intf_dists_info.interface_line_attribute14      := NULL;
            lr_ra_intf_dists_info.interface_line_attribute15      := NULL;
            lr_ra_intf_dists_info.interface_line_attribute9       := NULL;
            lr_ra_intf_dists_info.created_by                      := FND_GLOBAL.USER_ID;
            lr_ra_intf_dists_info.creation_date                   := SYSDATE;
            lr_ra_intf_dists_info.last_updated_by                 := FND_GLOBAL.USER_ID;
            lr_ra_intf_dists_info.last_update_date                := SYSDATE;
            lr_ra_intf_dists_info.last_update_login               := FND_GLOBAL.USER_ID;
            lr_ra_intf_dists_info.org_id                          := FND_PROFILE.VALUE('ORG_ID');
            lr_ra_intf_dists_info.interim_tax_ccid                := NULL;
            lr_ra_intf_dists_info.interim_tax_segment1            := NULL;
            lr_ra_intf_dists_info.interim_tax_segment2            := NULL;
            lr_ra_intf_dists_info.interim_tax_segment3            := NULL;
            lr_ra_intf_dists_info.interim_tax_segment4            := NULL;
            lr_ra_intf_dists_info.interim_tax_segment5            := NULL;
            lr_ra_intf_dists_info.interim_tax_segment6            := NULL;
            lr_ra_intf_dists_info.interim_tax_segment7            := NULL;
            lr_ra_intf_dists_info.interim_tax_segment8            := NULL;
            lr_ra_intf_dists_info.interim_tax_segment9            := NULL;
            lr_ra_intf_dists_info.interim_tax_segment10           := NULL;
            lr_ra_intf_dists_info.interim_tax_segment11           := NULL;
            lr_ra_intf_dists_info.interim_tax_segment12           := NULL;
            lr_ra_intf_dists_info.interim_tax_segment13           := NULL;
            lr_ra_intf_dists_info.interim_tax_segment14           := NULL;
            lr_ra_intf_dists_info.interim_tax_segment15           := NULL;
            lr_ra_intf_dists_info.interim_tax_segment16           := NULL;
            lr_ra_intf_dists_info.interim_tax_segment17           := NULL;
            lr_ra_intf_dists_info.interim_tax_segment18           := NULL;
            lr_ra_intf_dists_info.interim_tax_segment19           := NULL;
            lr_ra_intf_dists_info.interim_tax_segment20           := NULL;
            lr_ra_intf_dists_info.interim_tax_segment21           := NULL;
            lr_ra_intf_dists_info.interim_tax_segment22           := NULL;
            lr_ra_intf_dists_info.interim_tax_segment23           := NULL;
            lr_ra_intf_dists_info.interim_tax_segment24           := NULL;
            lr_ra_intf_dists_info.interim_tax_segment25           := NULL;
            lr_ra_intf_dists_info.interim_tax_segment26           := NULL;
            lr_ra_intf_dists_info.interim_tax_segment27           := NULL;
            lr_ra_intf_dists_info.interim_tax_segment28           := NULL;
            lr_ra_intf_dists_info.interim_tax_segment29           := NULL;
            lr_ra_intf_dists_info.interim_tax_segment30           := NULL;
            lr_ra_intf_dists_info.global_attribute1               := NULL;
            lr_ra_intf_dists_info.global_attribute2               := NULL;
            lr_ra_intf_dists_info.global_attribute3               := NULL;
            lr_ra_intf_dists_info.global_attribute4               := NULL;
            lr_ra_intf_dists_info.global_attribute5               := NULL;
            lr_ra_intf_dists_info.global_attribute6               := NULL;
            lr_ra_intf_dists_info.global_attribute7               := NULL;
            lr_ra_intf_dists_info.global_attribute8               := NULL;
            lr_ra_intf_dists_info.global_attribute9               := NULL;
            lr_ra_intf_dists_info.global_attribute10              := NULL;
            lr_ra_intf_dists_info.global_attribute11              := NULL;
            lr_ra_intf_dists_info.global_attribute12              := NULL;
            lr_ra_intf_dists_info.global_attribute13              := NULL;
            lr_ra_intf_dists_info.global_attribute14              := NULL;
            lr_ra_intf_dists_info.global_attribute15              := NULL;
            lr_ra_intf_dists_info.global_attribute16              := NULL;
            lr_ra_intf_dists_info.global_attribute17              := NULL;
            lr_ra_intf_dists_info.global_attribute18              := NULL;
            lr_ra_intf_dists_info.global_attribute19              := NULL;
            lr_ra_intf_dists_info.global_attribute20              := NULL;
            lr_ra_intf_dists_info.global_attribute21              := NULL;
            lr_ra_intf_dists_info.global_attribute22              := NULL;
            lr_ra_intf_dists_info.global_attribute23              := NULL;
            lr_ra_intf_dists_info.global_attribute24              := NULL;
            lr_ra_intf_dists_info.global_attribute25              := NULL;
            lr_ra_intf_dists_info.global_attribute26              := NULL;
            lr_ra_intf_dists_info.global_attribute27              := NULL;
            lr_ra_intf_dists_info.global_attribute28              := NULL;
            lr_ra_intf_dists_info.global_attribute29              := NULL;
            lr_ra_intf_dists_info.global_attribute30              := NULL;
            lr_ra_intf_dists_info.global_attribute_category       := NULL;
          
            lc_action :=  'Calling insert_ra_interface_dists_all for tax';
          
            insert_ra_interface_dists_all(p_ra_interface_dists_all_info => lr_ra_intf_dists_info);
          
            --End of Populate ra_interface_distributions_all for tax records

          END IF;

          px_subscription_array(indx).invoice_interfaced_flag := 'Y';
          px_subscription_array(indx).invoice_number          := ln_trx_number;  
          
        END IF; -- IF px_subscription_array(indx).billing_sequene_number != 1

        lc_action := 'Calling update_subscription_info';

        update_subscription_info(px_subscription_info => px_subscription_array(indx));

      EXCEPTION
      WHEN le_processing
      THEN
        lr_subscription_error_info                         := NULL;
        lr_subscription_error_info.contract_id             := px_subscription_array(indx).contract_id;
        lr_subscription_error_info.contract_number         := px_subscription_array(indx).contract_number;
        lr_subscription_error_info.contract_line_number    := px_subscription_array(indx).contract_line_number;
        lr_subscription_error_info.billing_sequence_number := px_subscription_array(indx).billing_sequence_number;
        lr_subscription_error_info.error_module            := lc_procedure_name;
        lr_subscription_error_info.error_message           := SUBSTR('Action: ' || lc_action || ' Error: ' || lc_error, 1, gc_max_err_size);
        lr_subscription_error_info.creation_date           := SYSDATE;

        lc_action := 'Calling insert_subscription_error_info';

        insert_subscription_error_info(p_subscription_error_info => lr_subscription_error_info);

        lc_invoice_interfaced_flag   := 'E';
        lc_invoice_interfacing_error := SUBSTR(lr_subscription_error_info.error_message, 1, gc_max_sub_err_size);

        RAISE le_processing;

       WHEN OTHERS
       THEN

        lr_subscription_error_info                         := NULL;
        lr_subscription_error_info.contract_id             := px_subscription_array(indx).contract_id;
        lr_subscription_error_info.contract_number         := px_subscription_array(indx).contract_number;
        lr_subscription_error_info.contract_line_number    := px_subscription_array(indx).contract_line_number;
        lr_subscription_error_info.billing_sequence_number := px_subscription_array(indx).billing_sequence_number;
        lr_subscription_error_info.error_module            := lc_procedure_name;
        lr_subscription_error_info.error_message           := SUBSTR('Action: ' || lc_action || ' Error: ' || SQLCODE || ' ' || SQLERRM, 1, gc_max_err_size);
        lr_subscription_error_info.creation_date           := SYSDATE;

        lc_action := 'Calling insert_subscription_error_info';

        insert_subscription_error_info(p_subscription_error_info => lr_subscription_error_info);

        lc_invoice_interfaced_flag   := 'E';
        lc_invoice_interfacing_error := SUBSTR(lr_subscription_error_info.error_message, 1, gc_max_sub_err_size);

        RAISE le_processing;

      END;

    END LOOP;

    exiting_sub(p_procedure_name => lc_procedure_name);

  EXCEPTION
  WHEN le_skip
  THEN
    logit(p_message => 'Skipping: ' || lc_error);
  WHEN le_processing
  THEN

    ROLLBACK TO sp_transaction;

    /********************************************
    * Update subscription with error information.
    ********************************************/

    FOR indx IN 1 .. px_subscription_array.COUNT
    LOOP

      px_subscription_array(indx).invoice_interfaced_flag   := lc_invoice_interfaced_flag;
      px_subscription_array(indx).invoice_number            := NULL;
      px_subscription_array(indx).invoice_interfacing_error := lc_invoice_interfacing_error;

      lc_action := 'Calling update_subscription_info to update with error info';

      update_subscription_info(px_subscription_info => px_subscription_array(indx));
    END LOOP;

    exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => TRUE);

    RAISE_APPLICATION_ERROR(-20101, 'PROCEDURE: ' || lc_procedure_name || ' Error: ' || lc_invoice_interfacing_error);

  WHEN OTHERS
  THEN

    ROLLBACK TO sp_transaction;

    /********************************************
    * Update subscription with error information.
    ********************************************/

    FOR indx IN 1 .. px_subscription_array.COUNT
    LOOP

      px_subscription_array(indx).invoice_interfaced_flag   := 'E';
      px_subscription_array(indx).invoice_number            := NULL;
      px_subscription_array(indx).invoice_interfacing_error := SUBSTR('Action: ' || lc_action || ' SQLCODE: ' || SQLCODE || ' SQLERRM: ' || SQLERRM, 1, gc_max_sub_err_size);

      lc_action := 'Calling update_subscription_info to update with error info';

      update_subscription_info(px_subscription_info => px_subscription_array(indx));
    END LOOP;

    exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => TRUE);

    RAISE_APPLICATION_ERROR(-20101, 'PROCEDURE: ' || lc_procedure_name || ' Action: ' || lc_action || ' SQLCODE: ' || SQLCODE || ' SQLERRM: ' || SQLERRM);

  END populate_invoice_interface;

  /********************************************
  * Helper procedure to get invoice information
  *********************************************/

  PROCEDURE get_invoice_information(p_contract_info       IN            xx_ar_contracts%ROWTYPE
                                   ,px_subscription_array IN OUT NOCOPY subscription_table)
  IS

    CURSOR c_ra_intf_lines(p_contract_number          IN xx_ar_subscriptions.contract_number%TYPE,
                           p_contract_line_number     IN xx_ar_subscriptions.contract_line_number%TYPE,
                           p_billing_sequence_number  IN xx_ar_subscriptions.billing_sequence_number%TYPE)
    IS
      SELECT * 
      FROM   ra_interface_lines_all rila
      WHERE  rila.interface_line_context = 'RECURRING BILLING'
      AND    DECODE(INSTR(rila.interface_line_attribute5, '-TAX'), 0, rila.interface_line_attribute5, 
                    SUBSTR(rila.interface_line_attribute5, 1, (INSTR(rila.interface_line_attribute5, '-TAX')-1))
                   )                    = p_contract_number
      AND    DECODE(INSTR(rila.interface_line_attribute3, '-TAX'), 0, rila.interface_line_attribute3, 
                    SUBSTR(rila.interface_line_attribute3, 1, (INSTR(rila.interface_line_attribute3, '-TAX')-1))
                   )                    = p_contract_line_number
      AND    DECODE(INSTR(rila.interface_line_attribute4, '-TAX'), 0, rila.interface_line_attribute4, 
                    SUBSTR(rila.interface_line_attribute4, 1, (INSTR(rila.interface_line_attribute4, '-TAX')-1))
                   )                    = p_billing_sequence_number;

    CURSOR c_ra_intf_errors(p_interface_line_id IN ra_interface_lines_all.interface_line_id%TYPE)
    IS
      SELECT * 
      FROM   ra_interface_errors_all riea
      WHERE  riea.interface_line_id = p_interface_line_id;

    lc_procedure_name          CONSTANT VARCHAR2(61) := gc_package_name || '.' || 'get_invoice_information';

    lt_parameters              gt_input_parameters;

    lr_invoice_header_info     ra_customer_trx_all%ROWTYPE;

    lc_transaction             VARCHAR2(5000);

    lc_error                   VARCHAR2(1000);

    lc_action                  VARCHAR2(1000);

    ln_loop_counter            NUMBER                                           := 0;

    lc_invoice_created_flag    xx_ar_subscriptions.invoice_created_flag%TYPE    := 'N';
    
    lc_invoice_interfaced_flag xx_ar_subscriptions.invoice_interfaced_flag%TYPE := 'N';

    lc_invoice_creation_error  xx_ar_subscriptions.invoice_creation_error%TYPE  := NULL;

    lr_subscription_error_info xx_ar_subscriptions_error%ROWTYPE;

    le_skip                    EXCEPTION;
    
    l_credit_check_flag        VARCHAR2(2)                                       := 'N';
    
    l_AB_flag                  VARCHAR2(2)                                       := 'N';

  BEGIN

    entering_sub(p_procedure_name  => lc_procedure_name,
                 p_parameters      => lt_parameters);

    /*********************************************************************************
    * Validate we have all the information in subscriptions needed to get invoice info
    *********************************************************************************/

    lc_action := 'Looping thru subscription array for prevalidation';

    FOR indx IN 1 .. px_subscription_array.COUNT
    LOOP

      /*********************************************
      * Validate ra interface tables were populated
      ********************************************/

      IF px_subscription_array(indx).invoice_number IS NULL 
      THEN
        lc_error := 'ra interface tables were not populated';
        RAISE le_skip;
      END IF;

      /************************************************************************
      * Validate we are still need to check if invoice was successfully created
      ************************************************************************/

      IF px_subscription_array(indx).invoice_created_flag NOT IN ('N', 'E')
      THEN
        lc_error := 'Invoice created flag: ' || px_subscription_array(indx).invoice_created_flag;
        RAISE le_skip;
      END IF;

    END LOOP;

    SAVEPOINT sp_transaction;

    /*****************************
    * Loop thru subscription array 
    *****************************/

    lc_action := 'Looping thru subscription array to validate invoice creation';

    FOR indx IN 1 .. px_subscription_array.COUNT
    LOOP

      /*********************
      * Only enter here once 
      *********************/

      IF (ln_loop_counter = 0) 
      THEN

        ln_loop_counter := ln_loop_counter + 1;

        /********************************************
        * Checking to see if the invoice was created.
        ********************************************/

        BEGIN

          lc_action := 'Calling get_invoice_header_info.';

          get_invoice_header_info(p_invoice_number      => px_subscription_array(indx).invoice_number,
                                  x_invoice_header_info => lr_invoice_header_info);

          lc_invoice_created_flag    := 'Y';
          lc_invoice_interfaced_flag := 'Y';
          lc_invoice_creation_error  := NULL; 
          
          /********************************************************************
          * Validate if there is credit limit for AB customer to create invoice
          ********************************************************************/         
          IF p_contract_info.payment_type = 'AB' --AND ln_loop_counter = 0
          THEN
            
            lc_action := 'Calling get_credit_limit_check';
            
            ln_loop_counter := ln_loop_counter + 1;
            
            get_credit_limit_check(p_contract_info           => p_contract_info,
                                   p_billing_sequence_number => px_subscription_array(indx).billing_sequence_number,
                                   p_invoice_number          => px_subscription_array(indx).invoice_number,
                                   x_credit_check_flag       => l_credit_check_flag);
                                   
            IF l_credit_check_flag != 'Y'
            THEN
              lc_error := 'Credit check flag : '|| l_credit_check_flag;  
              
              lc_action := 'Calling send_email_AB';
              
              --send email to credit department when customer does not meet credit limit
              send_email_AB(p_contract_info           => p_contract_info,
                            p_billing_sequence_number => px_subscription_array(indx).billing_sequence_number,
                            p_invoice_number          => px_subscription_array(indx).invoice_number,
                            p_AB_flag                 => l_AB_flag);  
              
              logit(p_message => 'Email sent to credit dept for AB customer credit limit check : '||l_AB_flag);           
          
            END IF;
          
          END IF;

        EXCEPTION
          WHEN OTHERS
          THEN

            logit(p_message => 'Invoice not created: ' || px_subscription_array(indx).invoice_number);

        END;

      END IF; --ln_loop_counter = 0
      
      /************************************************************
      * If invoice was not found, checking the ra interface tables.
      ************************************************************/

      IF (lc_invoice_created_flag != 'Y') 
      THEN

        /*********************************
        * Loop thru ra_interface_lines_all 
        *********************************/

        lc_action := 'Looping thru ra_interface_lines_all';

        FOR ra_intf_line_rec IN c_ra_intf_lines(p_contract_number          => px_subscription_array(indx).contract_number,
                                                p_contract_line_number     => px_subscription_array(indx).contract_line_number,
                                                p_billing_sequence_number  => px_subscription_array(indx).billing_sequence_number)
        LOOP

          lc_transaction := 'ra_interface_lines_all.interface_line_id: ' || ra_intf_line_rec.interface_line_id
                            ||  ' ra_interface_lines_all.interface_status: ' || ra_intf_line_rec.interface_status;

          logit(p_message => lc_transaction);

          /**********************************
          * Loop thru ra_interface_errors_all 
          **********************************/

          lc_action := 'Looping thru ra_interface_errors_all';

          FOR ra_intf_error_rec IN c_ra_intf_errors(p_interface_line_id => ra_intf_line_rec.interface_line_id)
          LOOP

            lr_subscription_error_info                         := NULL;
            lr_subscription_error_info.contract_id             := px_subscription_array(indx).contract_id;
            lr_subscription_error_info.contract_number         := px_subscription_array(indx).contract_number;
            lr_subscription_error_info.contract_line_number    := NULL; 
            lr_subscription_error_info.billing_sequence_number := px_subscription_array(indx).billing_sequence_number;
            lr_subscription_error_info.error_module            := lc_procedure_name;
            lr_subscription_error_info.error_message           := SUBSTR('ra_interface_errors_all.interface_line_id: ' || ra_intf_line_rec.interface_line_id ||
                                                                         ' Error: '  || ra_intf_error_rec.message_text, 1, gc_max_err_size);
            lr_subscription_error_info.creation_date           := SYSDATE;

            lc_action := 'Calling insert_subscription_error_info';

            insert_subscription_error_info(p_subscription_error_info => lr_subscription_error_info);

            lc_invoice_created_flag    := 'E';
            
            lc_invoice_interfaced_flag := 'E';

            lc_invoice_creation_error  := SUBSTR(lc_invoice_creation_error || ' - ' || lr_subscription_error_info.error_message, 1, gc_max_sub_err_size);

            /**************************************************************
            * If error found, delete ra_interface_distributions_all records
            **************************************************************/

            IF (ra_intf_error_rec.interface_distribution_id IS NOT NULL)
            THEN

              lc_action := 'Deleting ra_interface_distributions_all related to errors';

              logit(p_message => lc_action);

              DELETE ra_interface_distributions_all
              WHERE  interface_distribution_id = ra_intf_error_rec.interface_distribution_id;

              logit(p_message => 'Number of records deleted: ' || SQL%ROWCOUNT);

            END IF;

          END LOOP; -- FOR ra_intf_error_rec


          /********************************************
          * If error found, delete ra interface records
          ********************************************/
          IF (lc_invoice_created_flag = 'E')
          THEN

            lc_action := 'Deleting ra_interface_errors_all';

            logit(p_message => lc_action);

            DELETE ra_interface_errors_all
            WHERE  interface_line_id = ra_intf_line_rec.interface_line_id;

            logit(p_message => 'Number of records deleted: ' || SQL%ROWCOUNT);

            /*************************************************************
            * If error found, delete ra_interface_distributions_all record
            *************************************************************/

            lc_action := 'Deleting ra_interface_distributions_all';

            logit(p_message => lc_action);

            DELETE ra_interface_distributions_all
            WHERE  interface_line_id = ra_intf_line_rec.interface_line_id;

            logit(p_message => 'Number of records deleted: ' || SQL%ROWCOUNT);
            
            /*****************************************************
            * If error found, delete ra_interface_lines_all record
            *****************************************************/

            lc_action := 'Deleting ra_interface_lines_all';

            logit(p_message => lc_action);

            DELETE ra_interface_lines_all
            WHERE  interface_line_id = ra_intf_line_rec.interface_line_id;

            logit(p_message => 'Number of records deleted: ' || SQL%ROWCOUNT);

          END IF;

        END LOOP;  -- FOR ra_intf_line_rec 

      END IF; -- IF (lc_invoice_created_flag != 'Y') 

      /*******************************************************
      * Update subscription with invoice creation information.
      *******************************************************/

      px_subscription_array(indx).invoice_created_flag    := lc_invoice_created_flag;
      px_subscription_array(indx).invoice_interfaced_flag := lc_invoice_interfaced_flag;
      px_subscription_array(indx).invoice_creation_error  := lc_invoice_creation_error;

      lc_action := 'Calling update_subscription_info to update with error info';

      update_subscription_info(px_subscription_info => px_subscription_array(indx));

    END LOOP; --  FOR indx IN 1 .. px_subscription_array.COUNT

    COMMIT;

    exiting_sub(p_procedure_name => lc_procedure_name);

  EXCEPTION
  WHEN le_skip
  THEN
    logit(p_message => 'Skipping: ' || lc_error);

  WHEN OTHERS
  THEN

    ROLLBACK TO sp_transaction;

    exiting_sub(p_procedure_name => lc_procedure_name,
                p_exception_flag => TRUE);

    RAISE_APPLICATION_ERROR(-20101, 'PROCEDURE: ' || lc_procedure_name || ' Action: ' || lc_action || ' SQLCODE: ' || SQLCODE || ' SQLERRM: ' || SQLERRM);

  END get_invoice_information;

  /******************************************************************
  * Helper procedure to get trans id by performing $0 authorization
  ****************************************************************/

  PROCEDURE get_cc_trans_id_information(p_program_setups      IN            gt_translation_values,
                                        p_contract_info       IN            xx_ar_contracts%ROWTYPE,
                                        px_subscription_array IN OUT NOCOPY subscription_table)
  IS

    lc_procedure_name    CONSTANT  VARCHAR2(61) := gc_package_name || '.' || 'get_cc_trans_id_information';

    lt_parameters                  gt_input_parameters;

    lc_action                      VARCHAR2(1000);

    lc_error                       VARCHAR2(1000);

    lc_decrypted_value             xx_ar_contracts.card_token%TYPE;

    lc_encrypted_value             xx_ar_contracts.card_token%TYPE;

    ln_loop_counter                NUMBER := 0;

    lc_key_label                   xx_ar_contracts.card_encryption_label%TYPE;

    lr_order_header_info           oe_order_headers_all%ROWTYPE;

    lr_invoice_header_info         ra_customer_trx_all%ROWTYPE;

    ln_invoice_total_amount_info   ra_customer_trx_lines_all.extended_amount%TYPE;

    lr_bill_to_cust_acct_site_info hz_cust_acct_sites_all%ROWTYPE;

    lr_bill_to_cust_location_info  hz_locations%ROWTYPE;

    lc_billing_application_id      xx_ar_contracts.payment_identifier%TYPE;

    lc_wallet_id                   xx_ar_contracts.payment_identifier%TYPE;

    lc_auth_payload                VARCHAR2(32000);

    lr_subscription_error_info     xx_ar_subscriptions_error%ROWTYPE;

    lc_expiration_date             VARCHAR2(4);

    l_request                      UTL_HTTP.req;

    l_response                     UTL_HTTP.resp;

    lclob_buffer                   CLOB;

    lc_buffer                      VARCHAR2(10000);

    lr_subscription_payload_info   xx_ar_subscription_payloads%ROWTYPE;

    lr_subscription_info           xx_ar_subscriptions%ROWTYPE;

    le_skip                        EXCEPTION;

    le_processing                  EXCEPTION;

    le_avs_exception                EXCEPTION;
       
    le_invalid_card                EXCEPTION;
    
    lr_contract_line_info          xx_ar_contract_lines%ROWTYPE;
    
    l_day                          NUMBER;
    
    lr_pos_ordt_info               xx_ar_order_receipt_dtl%ROWTYPE;
    
    lr_pos_info                    xx_ar_pos_inv_order_ref%ROWTYPE;
    
    lr_customer_info               hz_cust_accounts%ROWTYPE;
       
    lc_subscription_error          xx_ar_subscriptions.subscription_error%TYPE;
    
    lc_cof_trans_id_flag           xx_ar_subscriptions.cof_trans_id_flag%TYPE;
    
    lc_avs_code                    xx_ar_subscriptions.auth_avs_code%TYPE;
    
    lc_last_auth_attempt_date      xx_ar_subscriptions.last_auth_attempt_date%TYPE;
    
    lc_email_sent_flag             xx_ar_subscriptions.email_sent_flag%TYPE;
    
    lc_history_sent_flag           xx_ar_subscriptions.history_sent_flag%TYPE;
    
    lc_payment_status              xx_ar_subscriptions.payment_status%TYPE;

    lc_contract_status             xx_ar_subscriptions.contract_status%TYPE;

    lc_next_retry_day              xx_ar_subscriptions.next_retry_day%TYPE;
    
  BEGIN

    entering_sub(p_procedure_name  => lc_procedure_name,
                 p_parameters      => lt_parameters);

    /***********************************************************************************
    * Validate we have all the information in subscriptions needed to create the invoice
    ***********************************************************************************/

    lc_action := 'Looping thru subscription array for prevalidation';

    FOR indx IN 1 .. px_subscription_array.COUNT
    LOOP

      /*****************************
      * Validate invoice was created
      *****************************/

      IF px_subscription_array(indx).invoice_created_flag != 'Y'
      THEN

        lc_error := 'Invoice not created';
        RAISE le_skip;

      END IF;
      
      /******************************
      * Validate trans id information
      ******************************/
      IF p_contract_info.cc_trans_id IS NOT NULL
      THEN
        lc_error := 'cc_trans_id is: ' || p_contract_info.cc_trans_id;
        RAISE le_skip;
      END IF;
      
      /*******************************
      * Validate card type information
      *******************************/
      IF p_contract_info.payment_type != 'CreditCard'
      THEN
        lc_error := 'payment_type is: ' || p_contract_info.payment_type;
        RAISE le_skip;
      END IF;

      /*************************************
      * Validate we are read to perform auth
      *************************************/
      IF px_subscription_array(indx).cof_trans_id_flag NOT IN ('E','N','U') 
      THEN
        lc_error := 'Trans ID flag: ' || px_subscription_array(indx).cof_trans_id_flag;
        RAISE le_skip;
      END IF;
      
      /*************************************
      * Validate we are read to perform auth
      *************************************/
      IF px_subscription_array(indx).auth_completed_flag NOT IN ('E','N','U') 
      THEN
        lc_error := 'Authorization flag: ' || px_subscription_array(indx).auth_completed_flag;
        RAISE le_skip;
      END IF;

    END LOOP;

    lc_action := 'Setting transaction savepoint';

    SAVEPOINT sp_transaction;

    /***********************************************************************
    * Loop thru all the information in subscriptions for interfacing invoice
    ***********************************************************************/

    lc_action := 'Looping thru subscription array for authorization';

    FOR indx IN 1 .. px_subscription_array.COUNT
    LOOP
      BEGIN

        /******************************
        * Get contract line information
        ******************************/

        lc_action := 'Calling get_contract_line_info at get_cc_trans_id_information :';

        get_contract_line_info(p_contract_id          => px_subscription_array(indx).contract_id,
                               p_contract_line_number => px_subscription_array(indx).contract_line_number,
                               x_contract_line_info   => lr_contract_line_info);

        IF px_subscription_array(indx).billing_sequence_number >= lr_contract_line_info.initial_billing_sequence
        THEN
          
          /*****************************************************
          * Get day information when do we need to authorizaiton
          *****************************************************/
          
          lc_action := 'Calling get_auth_day_info';
          
          l_day := TO_DATE(TO_CHAR(SYSDATE,'DD-MON-YYYY')||'00:00:00','DD-MON-YYYY HH24:MI:SS') 
                  - NVL(TO_DATE(px_subscription_array(indx).initial_auth_attempt_date,'DD-MON-YYYY HH24:MI:SS')
                        ,TO_DATE(TO_CHAR(SYSDATE,'DD-MON-YYYY')||'00:00:00','DD-MON-YYYY HH24:MI:SS'));
 
          get_auth_day_info(p_auth_day => l_day);
          
          --payment authorization should be done according to the days mentioned in translation
          IF l_day >= 0
             OR (TRUNC(p_contract_info.payment_last_update_date) >= TRUNC(px_subscription_array(indx).last_auth_attempt_date) )
             OR (px_subscription_array(indx).cof_trans_id_flag = 'U')
          THEN
        
            IF ln_loop_counter = 0
            THEN
            
              ln_loop_counter := ln_loop_counter + 1;
            
              /**********************************
              *  Decrypt card except for 'PAYPAL'
              **********************************/
            
              IF p_contract_info.card_type != 'PAYPAL'
              THEN
            
                /**************
                * Decrypt Value
                **************/
            
                lc_action := 'Calling decrypt_credit_card';
            
                decrypt_credit_card(p_context_namespace => 'XX_AR_SUBSCRIPTIONS_MT_CTX',
                                    p_context_attribute => 'TYPE',
                                    p_context_value     => 'OM',
                                    p_module            => 'HVOP',
                                    p_format            => 'EBCDIC',
                                    p_encrypted_value   => p_contract_info.card_token,
                                    p_key_label         => p_contract_info.card_encryption_label,
                                    x_decrypted_value   => lc_decrypted_value);
                       
              END IF;
              
              /*************************************************************************
              * update the settlement_card, settlement_label and settlement_cc_mask     
              * to subscription table, so that even if card authorization fails we will 
              * able to capture card details for sending email for unsuccessful payments
              *************************************************************************/
            
              lc_action := 'Updating credit card details';
            
              IF lc_decrypted_value IS NOT NULL 
              THEN
                px_subscription_array(indx).settlement_cc_mask  := SUBSTR(lc_decrypted_value, 1, 6) || SUBSTR(lc_decrypted_value, LENGTH(lc_decrypted_value) - 3, 4);
            
                lc_action := 'Calling update_subscription_info';
            
                update_subscription_info(px_subscription_info => px_subscription_array(indx));
            
              END IF;
            
              /******************************
              * Get initial order header info
              ******************************/
            
              lc_action := 'Calling get_order_header_info';
            
              IF p_contract_info.external_source = 'POS'
              THEN
                get_pos_ordt_info(p_order_number => p_contract_info.initial_order_number,
                      x_ordt_info    => lr_pos_ordt_info);
                      
                get_pos_info(p_header_id        => lr_pos_ordt_info.header_id,
                             p_orig_sys_doc_ref => p_contract_info.initial_order_number,
                             x_pos_info         => lr_pos_info);
                             
                get_order_header_info(--p_order_number      => lr_pos_info.sales_order,            --Commented for NAIT-126620.
                                      p_order_number      => p_contract_info.initial_order_number, --Added for NAIT-126620
                                      x_order_header_info => lr_order_header_info);
              ELSE
                get_order_header_info(p_order_number      => p_contract_info.initial_order_number,
                                      x_order_header_info => lr_order_header_info);
              END IF;
            
              /*************************************************
              * Get initial order BILL_TO cust account site info
              *************************************************/
            
              lc_action := 'Calling get_cust_account_site_info for BILL_TO';
            
              IF p_contract_info.external_source = 'POS'
              THEN
                get_customer_pos_info(p_aops           => p_contract_info.bill_to_osr,
                                      x_customer_info  => lr_customer_info);
                                    
                get_cust_site_pos_info(p_customer_id     => lr_customer_info.cust_account_id,
                                       x_cust_site_info  => lr_bill_to_cust_acct_site_info);
              ELSE
                get_cust_account_site_info(p_site_use_id            => lr_order_header_info.invoice_to_org_id,
                                           p_site_use_code          => 'BILL_TO',
                                           x_cust_account_site_info => lr_bill_to_cust_acct_site_info);
              END IF;
            
              /***********************************
              * Get initial order BILL_TO location
              ***********************************/
            
              lc_action := 'Calling get_cust_location_info for BILL_TO';
            
              get_cust_location_info(p_cust_acct_site_id  => lr_bill_to_cust_acct_site_info.cust_acct_site_id,
                                     x_cust_location_info => lr_bill_to_cust_location_info);
                        
              /**********************************************************************
              * If paypal, pass billing application id, if masterpass, pass wallet id
              **********************************************************************/
            
              IF p_contract_info.card_type = 'PAYPAL'
              THEN
                 lc_billing_application_id := p_contract_info.payment_identifier;
              ELSE
                 lc_wallet_id              := p_contract_info.payment_identifier;
              END IF;
            
              /***********************
              * Format expiration date
              ***********************/
            
              IF p_contract_info.card_expiration_date IS NOT NULL
              THEN
                lc_expiration_date := TO_CHAR(p_contract_info.card_expiration_date, 'YYMM');
              END IF;             
            
              /****************************
              * Build authorization payload
              ****************************/
            
              lc_action := 'Building authorization payload';
            
              SELECT    '{
                  "paymentAuthorizationRequest": {
                  "transactionHeader": {
                  "consumerName": "EBS",
                  "consumerTransactionId": "'
                             || p_contract_info.contract_number
                             || '-'
                             || TO_CHAR(SYSDATE,
                                        'DDMONYYYYHH24MISS')
                             || '",
                  "consumerTransactionDateTime":"'
                             || TO_CHAR(SYSDATE,
                                        'YYYY-MM-DD')
                             || 'T'
                             || TO_CHAR(SYSDATE,
                                        'HH24:MI:SS')
                             || '"
                    },
                  "customer": {
                  "firstName": "'
                             || p_contract_info.card_holder_name
                             || '",
                  "middleName": "",
                  "lastName": "",
                  "paymentDetails": {
                  "paymentType": "'
                             || p_contract_info.payment_type
                             || '",
                  "paymentCard": {
                  "cardHighValueToken": "'
                             || lc_decrypted_value
                             || '",
                  "expirationDate": "'
                             || lc_expiration_date
                             || '",
                  "amount": "0",
                  "cardType": "'
                             || p_contract_info.card_type
                             || '",
                  "applicationTransactionNumber": "'
                             || px_subscription_array(indx).invoice_number
                             || '",
                  "billingAddress": {
                  "name": "'
                             || p_contract_info.card_holder_name
                             || '",
                  "address": {
                  "address1": "'
                             || lr_bill_to_cust_location_info.address1
                             || '",
                  "address2": "'
                             || lr_bill_to_cust_location_info.address2
                             || '",
                  "city": "'
                             || lr_bill_to_cust_location_info.city
                             || '",
                  "state": "'
                             || lr_bill_to_cust_location_info.state
                             || '",
                  "postalCode": "'
                             || SUBSTR(lr_bill_to_cust_location_info.postal_code, 1, 5)
                             || '",
                  "country": "'
                             || lr_bill_to_cust_location_info.country
                             || '"
                  }
                  }
                  },
                  "billingAgreementId": "'
                             || lc_billing_application_id
                             || '",
                  "walletId": "'
                             || lc_wallet_id
                             || '",
                  "avsOnly": true
                  },
                  "contact": {
                  "email": "'
                             || p_contract_info.customer_email
                             || '",
                  "phoneNumber": "'
                           --  || lv_phone_number --??
                             || '",
                  "faxNumber": "'
                            -- || lv_fax_number --??
                             || '"
                  }
                  },
                "storeNumber": "'
                             || p_contract_info.store_number
                             || '",
                "contract": {
                    "contractId": "'
                             || p_contract_info.contract_id
                             || '",
                    "customerId": "'
                             || p_contract_info.bill_to_osr
                             || '"
                  }
                  }
                  }
                  '
              INTO   lc_auth_payload
              FROM   DUAL;
            
              lc_action := 'Validating Wallet location';
            
              IF p_program_setups('wallet_location') IS NOT NULL
              THEN
              
                lc_action := 'calling UTL_HTTP.set_wallet';
              
                UTL_HTTP.SET_WALLET(p_program_setups('wallet_location'), p_program_setups('wallet_password'));
              
              END IF;
              
              lc_action := 'Calling UTL_HTTP.begin_request';
            
              l_request := UTL_HTTP.begin_request(p_program_setups('auth_service_url'), 'POST', ' HTTP/1.1');
            
              lc_action := 'Calling UTL_HTTP.set_header';
            
              UTL_HTTP.set_header(l_request, 'user-agent', 'mozilla/4.0');
            
              UTL_HTTP.set_header(l_request, 'content-type', 'application/json');
            
              UTL_HTTP.set_header(l_request, 'Content-Length', LENGTH(lc_auth_payload));
            
              UTL_HTTP.set_header(l_request, 'Authorization', 'Basic ' || UTL_RAW.cast_to_varchar2(UTL_ENCODE.base64_encode(UTL_RAW.cast_to_raw(p_program_setups('auth_service_user')
                                                                                                                                                || ':' ||
                                                                                                                                                p_program_setups('auth_service_pwd')
                                                                                                                                                ))));
              lc_action := 'Calling UTL_HTTP.write_text';
            
              UTL_HTTP.write_text(l_request, lc_auth_payload);
            
              lc_action := 'Calling UTL_HTTP.get_response';
            
              l_response := UTL_HTTP.get_response(l_request);
            
              COMMIT;
            
              logit(p_message => 'Response status_code' || l_response.status_code);
            
              BEGIN
                lclob_buffer := EMPTY_CLOB;
                LOOP
                  UTL_HTTP.read_text(l_response, lc_buffer, LENGTH(lc_buffer));
                  lclob_buffer := lclob_buffer || lc_buffer;
                END LOOP;
            
                logit(p_message => 'Response Clob: ' || lclob_buffer);
            
                UTL_HTTP.end_response(l_response);
            
              EXCEPTION
              WHEN UTL_HTTP.end_of_body
              THEN
                 UTL_HTTP.end_response(l_response);
              END;
            
              /*********************
              * Masking credit card
              ********************/
            
              IF lc_decrypted_value IS NOT NULL
              THEN
                lc_action := 'Masking credit card';
            
                lc_auth_payload := REPLACE(lc_auth_payload, lc_decrypted_value, SUBSTR(lc_decrypted_value, 1, 6) || '*****' || SUBSTR(lc_decrypted_value, LENGTH(lc_decrypted_value) - 4, 4));
              END IF;
            
              /***********************
              * Store request/response
              ***********************/
            
              lc_action := 'Store request/response';
            
              lr_subscription_payload_info.payload_id              := xx_ar_subscription_payloads_s.NEXTVAL;
              lr_subscription_payload_info.response_data           := lclob_buffer;
              lr_subscription_payload_info.creation_date           := SYSDATE;
              lr_subscription_payload_info.created_by              := FND_GLOBAL.USER_ID;
              lr_subscription_payload_info.last_updated_by         := FND_GLOBAL.USER_ID;
              lr_subscription_payload_info.last_update_date        := SYSDATE;
              lr_subscription_payload_info.input_payload           := lc_auth_payload;
              lr_subscription_payload_info.contract_number         := px_subscription_array(indx).contract_number;
              lr_subscription_payload_info.billing_sequence_number := px_subscription_array(indx).billing_sequence_number;
              lr_subscription_payload_info.contract_line_number    := NULL;
              lr_subscription_payload_info.source                  := lc_procedure_name;
            
              lc_action := 'Calling insert_subscription_payload_info';
            
              insert_subscript_payload_info(p_subscription_payload_info => lr_subscription_payload_info);
            
              /*************************
              * Get response into a CLOB
              *************************/
            
              IF (l_response.status_code != 200)
              THEN
                lc_error := 'Failed response status_code: ' || l_response.status_code;
                RAISE le_processing;
              END IF;
            
              --BEGIN : JIRA#NAIT-92855:- EBS - Trigger AVS process -> Updating initial_auth_attempt_date with SYSDATE when auth for AVS code is done on DAY 1
              IF px_subscription_array(indx).initial_auth_attempt_date IS NULL
              THEN
                 px_subscription_array(indx).initial_auth_attempt_date := TO_DATE(TO_CHAR(SYSDATE,'DD-MON-YYYY')||'00:00:00','DD-MON-YYYY HH24:MI:SS');
              END IF;
              --END : JIRA#NAIT-92855:- EBS - Trigger AVS process -> Updating initial_auth_attempt_date with SYSDATE when auth for AVS code is done on DAY 1
              
              /**********************************
              * Get the authorization information
              **********************************/
            
              lr_subscription_info := px_subscription_array(indx);
            
              lc_action := 'Calling retrieve_auth_response_info';
            
              retrieve_auth_response_info(p_payload_id            => lr_subscription_payload_info.payload_id,
                                          px_ar_subscription_info => lr_subscription_info);
                        
              /**********************************************************
              * If authorization passed, record authorization information
              **********************************************************/
            
              IF ((p_contract_info.external_source = 'POS' AND p_program_setups('pos_avs_check_flag') = 'Y') 
               OR (p_contract_info.external_source != 'POS'))
              THEN
                IF (lr_subscription_info.auth_status = '0' AND lr_subscription_info.auth_avs_code = 'Y')
                THEN            
                  lc_action := 'assigning the auth success result to subscription array';               
                  px_subscription_array(indx).cof_trans_id            := lr_subscription_info.cof_trans_id;
                  px_subscription_array(indx).cof_trans_id_flag       := 'Y';
                  px_subscription_array(indx).last_auth_attempt_date  := SYSDATE;

                  
                  --call update contracts table with cc_trans_id and cc_trans_id_source
                  update_contracts_info(p_contract_id           => px_subscription_array(indx).contract_id
                                       ,p_cc_trans_id           => lr_subscription_info.cof_trans_id
                                       ,p_cc_trans_id_source    => 'EBS'
                                       ,p_cof_trans_id_scm_flag => 'N'
                                       );
                ELSE
                  lc_action := 'assigning the auth failure result to subscription array';
                  px_subscription_array(indx).subscription_error      := lr_subscription_info.auth_message;

                  --BEGIN : JIRA#NAIT-92855:- EBS - Trigger AVS process -> AVS CODE Change 1

                  px_subscription_array(indx)                         := lr_subscription_info;
                  px_subscription_array(indx).auth_status             := lr_subscription_info.auth_status;
                  px_subscription_array(indx).auth_message            := lr_subscription_info.auth_message;

                  IF SUBSTR(lr_subscription_info.auth_message,1,1) IN ('R','S')
                  THEN
                    lc_error             := 'Connectivity Isuue';
                    lc_cof_trans_id_flag := 'U';                    
                    RAISE le_processing;
                  ELSE
                    lc_error                                            := 'Invalid Card';
                    lc_cof_trans_id_flag                                := 'E';
                    px_subscription_array(indx).last_auth_attempt_date  := SYSDATE;
                    px_subscription_array(indx).payment_status          := 'FAILURE';
                    px_subscription_array(indx).contract_status         := NULL;
                    px_subscription_array(indx).next_retry_day          := NULL;
                    px_subscription_array(indx).email_sent_flag         := 'N';
                    px_subscription_array(indx).history_sent_flag       := 'N';
                    RAISE le_avs_exception;
                  END IF;
                  --END : JIRA#NAIT-92855:- EBS - Trigger AVS process -> AVS CODE Change 1
                END IF;
              ELSIF p_contract_info.external_source = 'POS' AND p_program_setups('pos_avs_check_flag') != 'Y'
              THEN
                IF lr_subscription_info.auth_status = '0' 
                THEN            
                  lc_action := 'assigning the auth success result to subscription array';               
                  px_subscription_array(indx).cof_trans_id            := lr_subscription_info.cof_trans_id;
                  px_subscription_array(indx).cof_trans_id_flag       := 'Y';
                  px_subscription_array(indx).last_auth_attempt_date  := SYSDATE;
                  
                  --call update contracts table with cc_trans_id and cc_trans_id_source
                  update_contracts_info(p_contract_id           => px_subscription_array(indx).contract_id
                                       ,p_cc_trans_id           => lr_subscription_info.cof_trans_id
                                       ,p_cc_trans_id_source    => 'EBS'
                                       ,p_cof_trans_id_scm_flag => 'N'
                                       );
                ELSE
                  lc_action := 'assigning the auth failure result to subscription array';
                  px_subscription_array(indx).subscription_error      := lr_subscription_info.auth_message;

                  --BEGIN : JIRA#NAIT-92855:- EBS - Trigger AVS process -> AVS CODE Change 2

                  lc_action := 'assigning the auth failure result to subscription array';
                
                  px_subscription_array(indx)                         := lr_subscription_info;
                  px_subscription_array(indx).auth_status             := lr_subscription_info.auth_status;
                  px_subscription_array(indx).auth_message            := lr_subscription_info.auth_message;

                  IF SUBSTR(lr_subscription_info.auth_message,1,1) IN ('R','S')
                  THEN
                    lc_error             := 'Connectivity Isuue';
                    lc_cof_trans_id_flag := 'U';                    
                    RAISE le_processing;
                  ELSE
                    lc_error                                            := 'Invalid Card';
                    lc_cof_trans_id_flag                                := 'E';
                    px_subscription_array(indx).last_auth_attempt_date  := SYSDATE;
                    px_subscription_array(indx).payment_status          := 'FAILURE';
                    px_subscription_array(indx).contract_status         := NULL;
                    px_subscription_array(indx).next_retry_day          := NULL;
                    px_subscription_array(indx).email_sent_flag         := 'N';
                    px_subscription_array(indx).history_sent_flag       := 'N';
                    RAISE le_avs_exception;
                  END IF;

                  --END : JIRA#NAIT-92855:- EBS - Trigger AVS process -> AVS CODE Change 2
                END IF;
              END IF;
            
            ELSE
              lc_action := 'Updating credit card details';
              
              px_subscription_array(indx).settlement_cc_mask  := SUBSTR(lc_decrypted_value, 1, 6) || SUBSTR(lc_decrypted_value, LENGTH(lc_decrypted_value) - 3, 4);
              
              --BEGIN : JIRA#NAIT-92855:- EBS - Trigger AVS process -> Updating initial_auth_attempt_date with SYSDATE when auth for AVS code is done on DAY 1
              IF px_subscription_array(indx).initial_auth_attempt_date IS NULL
              THEN
                 px_subscription_array(indx).initial_auth_attempt_date := TO_DATE(TO_CHAR(SYSDATE,'DD-MON-YYYY')||'00:00:00','DD-MON-YYYY HH24:MI:SS');
              END IF;
              --END : JIRA#NAIT-92855:- EBS - Trigger AVS process -> Updating initial_auth_attempt_date with SYSDATE when auth for AVS code is done on DAY 1

              /**********************************
              * Get the authorization information
              **********************************/
            
              lr_subscription_info := px_subscription_array(indx);
            
              lc_action := 'Calling retrieve_auth_response_info';
            
              retrieve_auth_response_info(p_payload_id            => lr_subscription_payload_info.payload_id,
                                          px_ar_subscription_info => lr_subscription_info);
                         
              /**********************************************************
              * If authorization passed, record authorization information
              **********************************************************/
            
              IF ((p_contract_info.external_source = 'POS' AND p_program_setups('pos_avs_check_flag') = 'Y') 
               OR (p_contract_info.external_source != 'POS'))
              THEN
                IF (lr_subscription_info.auth_status = '0' AND lr_subscription_info.auth_avs_code = 'Y')
                THEN            
                  lc_action := 'assigning the auth success result to subscription array';               
                  px_subscription_array(indx).cof_trans_id                := lr_subscription_info.cof_trans_id;
                  px_subscription_array(indx).cof_trans_id_flag           := 'Y';
                  px_subscription_array(indx).last_auth_attempt_date      := SYSDATE;

                  --call update contracts table with cc_trans_id and cc_trans_id_source
                  update_contracts_info(p_contract_id           => px_subscription_array(indx).contract_id
                                       ,p_cc_trans_id           => lr_subscription_info.cof_trans_id
                                       ,p_cc_trans_id_source    => 'EBS'
                                       ,p_cof_trans_id_scm_flag => 'N'
                                       );
                ELSE
                  lc_action := 'assigning the auth failure result to subscription array';
                  px_subscription_array(indx).subscription_error      := lr_subscription_info.auth_message;

                  --BEGIN : JIRA#NAIT-92855:- EBS - Trigger AVS process -> AVS CODE Change 3

                  lc_action := 'assigning the auth failure result to subscription array';
                
                  px_subscription_array(indx)                         := lr_subscription_info;
                  px_subscription_array(indx).auth_status             := lr_subscription_info.auth_status;
                  px_subscription_array(indx).auth_message            := lr_subscription_info.auth_message;

                  IF SUBSTR(lr_subscription_info.auth_message,1,1) IN ('R','S')
                  THEN
                    lc_error             := 'Connectivity Isuue';
                    lc_cof_trans_id_flag := 'U';                    
                    RAISE le_processing;
                  ELSE
                    lc_error                                            := 'Invalid Card';
                    lc_cof_trans_id_flag                                := 'E';
                    px_subscription_array(indx).last_auth_attempt_date  := SYSDATE;
                    px_subscription_array(indx).payment_status          := 'FAILURE';
                    px_subscription_array(indx).contract_status         := NULL;
                    px_subscription_array(indx).next_retry_day          := NULL;
                    px_subscription_array(indx).email_sent_flag         := 'N';
                    px_subscription_array(indx).history_sent_flag       := 'N';
                    RAISE le_avs_exception;
                  END IF;

                  --END : JIRA#NAIT-92855:- EBS - Trigger AVS process -> AVS CODE Change 3
                END IF;
              ELSIF p_contract_info.external_source = 'POS' AND p_program_setups('pos_avs_check_flag') != 'Y'
              THEN
                IF lr_subscription_info.auth_status = '0' 
                THEN            
                  lc_action := 'assigning the auth success result to subscription array';               
                  px_subscription_array(indx).cof_trans_id                := lr_subscription_info.cof_trans_id;
                  px_subscription_array(indx).cof_trans_id_flag           := 'Y';
                  px_subscription_array(indx).last_auth_attempt_date      := SYSDATE;

                 
                  --call update contracts table with cc_trans_id and cc_trans_id_source
                  update_contracts_info(p_contract_id           => px_subscription_array(indx).contract_id
                                       ,p_cc_trans_id           => lr_subscription_info.cof_trans_id
                                       ,p_cc_trans_id_source    => 'EBS'
                                       ,p_cof_trans_id_scm_flag => 'N'
                                       );
                ELSE
                  lc_action := 'assigning the auth failure result to subscription array';
                  px_subscription_array(indx).subscription_error      := lr_subscription_info.auth_message;

                  --BEGIN : JIRA#NAIT-92855:- EBS - Trigger AVS process -> AVS CODE Change 4

                  lc_action := 'assigning the auth failure result to subscription array';
                
                  px_subscription_array(indx)                         := lr_subscription_info;
                  px_subscription_array(indx).auth_status             := lr_subscription_info.auth_status;
                  px_subscription_array(indx).auth_message            := lr_subscription_info.auth_message;

                  IF SUBSTR(lr_subscription_info.auth_message,1,1) IN ('R','S')
                  THEN
                    lc_error             := 'Connectivity Isuue';
                    lc_cof_trans_id_flag := 'U';                    
                    RAISE le_processing;
                  ELSE
                    lc_error                                            := 'Invalid Card';
                    lc_cof_trans_id_flag                                := 'E';
                    px_subscription_array(indx).last_auth_attempt_date  := SYSDATE;
                    px_subscription_array(indx).payment_status          := 'FAILURE';
                    px_subscription_array(indx).contract_status         := NULL;
                    px_subscription_array(indx).next_retry_day          := NULL;
                    px_subscription_array(indx).email_sent_flag         := 'N';
                    px_subscription_array(indx).history_sent_flag       := 'N';
                    RAISE le_avs_exception;
                  END IF;

                  --END : JIRA#NAIT-92855:- EBS - Trigger AVS process -> AVS CODE Change 4

                END IF;
              END IF;
            
            END IF; -- IF ln_loop_counter = 0
            
          END IF;

        END IF; -- IF px_subscription_array(indx).billing_sequene_number != 1

        lc_action := 'Calling update_subscription_info';

        update_subscription_info(px_subscription_info => px_subscription_array(indx));

      EXCEPTION
      WHEN le_processing
      THEN

        lr_subscription_error_info                         := NULL;
        lr_subscription_error_info.contract_id             := px_subscription_array(indx).contract_id;
        lr_subscription_error_info.contract_number         := px_subscription_array(indx).contract_number;
        lr_subscription_error_info.contract_line_number    := NULL;
        lr_subscription_error_info.billing_sequence_number := px_subscription_array(indx).billing_sequence_number;
        lr_subscription_error_info.error_module            := lc_procedure_name;
        lr_subscription_error_info.error_message           := SUBSTR('Action: ' || lc_action || ' Error: ' || lc_error, 1, gc_max_err_size);
        lr_subscription_error_info.creation_date           := SYSDATE;

        lc_action := 'Calling insert_subscription_error_info';

        insert_subscription_error_info(p_subscription_error_info => lr_subscription_error_info);
       
        lc_cof_trans_id_flag := 'U';
        lc_subscription_error := SUBSTR(lr_subscription_error_info.error_message, 1, gc_max_sub_err_size);

        RAISE le_processing;

        --BEGIN : JIRA#NAIT-92855:- EBS - Trigger AVS process -> AVS EXCEPTION
        WHEN le_avs_exception
        THEN

        lr_subscription_error_info                         := NULL;
        lr_subscription_error_info.contract_id             := px_subscription_array(indx).contract_id;
        lr_subscription_error_info.contract_number         := px_subscription_array(indx).contract_number;
        lr_subscription_error_info.contract_line_number    := NULL;
        lr_subscription_error_info.billing_sequence_number := px_subscription_array(indx).billing_sequence_number;
        lr_subscription_error_info.error_module            := lc_procedure_name;
        lr_subscription_error_info.error_message           := SUBSTR('Action: ' || lc_action || ' Error: ' || lc_error, 1, gc_max_err_size);
        lr_subscription_error_info.creation_date           := SYSDATE;

        lc_action := 'Calling insert_subscription_error_info';

        insert_subscription_error_info(p_subscription_error_info => lr_subscription_error_info);

        lc_cof_trans_id_flag       := 'E';
        lc_last_auth_attempt_date  := SYSDATE;
        lc_email_sent_flag         := 'N';
        lc_history_sent_flag       := 'N';
        lc_payment_status          := 'FAILURE';
        lc_contract_status         := NULL;
        lc_next_retry_day          := NULL;
        lc_subscription_error      := SUBSTR(lr_subscription_error_info.error_message, 1, gc_max_sub_err_size);    

        RAISE le_avs_exception;      

      --END : JIRA#NAIT-92855:- EBS - Trigger AVS process -> AVS EXCEPTION
      
      WHEN OTHERS
      THEN

        lr_subscription_error_info                         := NULL;
        lr_subscription_error_info.contract_id             := px_subscription_array(indx).contract_id;
        lr_subscription_error_info.contract_number         := px_subscription_array(indx).contract_number;
        lr_subscription_error_info.contract_line_number    := NULL;
        lr_subscription_error_info.billing_sequence_number := px_subscription_array(indx).billing_sequence_number;
        lr_subscription_error_info.error_module            := lc_procedure_name;
        lr_subscription_error_info.error_message           := SUBSTR('Action: ' || lc_action || ' Error: ' || SQLCODE || ' ' || SQLERRM, 1, gc_max_err_size);
        lr_subscription_error_info.creation_date           := SYSDATE;

        lc_action := 'Calling insert_subscription_error_info';

        insert_subscription_error_info(p_subscription_error_info => lr_subscription_error_info);

        lc_cof_trans_id_flag := 'U';
        lc_subscription_error := SUBSTR(lr_subscription_error_info.error_message, 1, gc_max_sub_err_size);

        RAISE le_processing;

      END;

    END LOOP;

    exiting_sub(p_procedure_name => lc_procedure_name);

  EXCEPTION
  WHEN le_skip
  THEN
    logit(p_message => 'Skipping: ' || lc_error);

  WHEN le_processing
  THEN

    FOR indx IN 1 .. px_subscription_array.COUNT
    LOOP

      px_subscription_array(indx).cof_trans_id_flag  := lc_cof_trans_id_flag;
      px_subscription_array(indx).subscription_error := lc_subscription_error;

      lc_action := 'Calling update_subscription_info to update with error info';

      update_subscription_info(px_subscription_info => px_subscription_array(indx));

    END LOOP;

    exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => TRUE);
    RAISE_APPLICATION_ERROR(-20101, lc_subscription_error);

  --BEGIN : JIRA#NAIT-92855:- EBS - Trigger AVS process -> AVS EXCEPTION
  WHEN le_avs_exception
  THEN

    FOR indx IN 1 .. px_subscription_array.COUNT
    LOOP
    
      /**********************************
      * Get the authorization information
      **********************************/
      
      lr_subscription_info := px_subscription_array(indx);
      
      lc_action := 'Calling retrieve_auth_response_info';
      
      retrieve_auth_response_info(p_payload_id            => lr_subscription_payload_info.payload_id,
                                  px_ar_subscription_info => lr_subscription_info);
      
      px_subscription_array(indx)                           := lr_subscription_info;
      
      -- updating initial_auth_attempt_date with SYSDATE when auth is done on DAY 1
      IF px_subscription_array(indx).initial_auth_attempt_date IS NULL
      THEN
        px_subscription_array(indx).initial_auth_attempt_date := TO_DATE(TO_CHAR(SYSDATE,'DD-MON-YYYY')||'00:00:00','DD-MON-YYYY HH24:MI:SS');
      END IF;

      px_subscription_array(indx).cof_trans_id_flag       := lc_cof_trans_id_flag;
      px_subscription_array(indx).subscription_error      := lc_subscription_error;
      px_subscription_array(indx).last_auth_attempt_date  := lc_last_auth_attempt_date;
      px_subscription_array(indx).email_sent_flag         := lc_email_sent_flag;
      px_subscription_array(indx).payment_status          := lc_payment_status;
      px_subscription_array(indx).contract_status         := lc_contract_status;
      px_subscription_array(indx).next_retry_day          := lc_next_retry_day;
      px_subscription_array(indx).history_sent_flag       := lc_history_sent_flag;
      
      lc_action := 'Updating credit card details';
      
      px_subscription_array(indx).settlement_cc_mask  := SUBSTR(lc_decrypted_value, 1, 6) || SUBSTR(lc_decrypted_value, LENGTH(lc_decrypted_value) - 3, 4);

      lc_action := 'Calling update_subscription_info to update with error info';

      update_subscription_info(px_subscription_info => px_subscription_array(indx));

    END LOOP;  

    exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => TRUE);
    RAISE_APPLICATION_ERROR(-20101, lc_subscription_error);
--END : JIRA#NAIT-92855:- EBS - Trigger AVS process -> AVS EXCEPTION

  WHEN OTHERS
  THEN

    FOR indx IN 1 .. px_subscription_array.COUNT
    LOOP

      px_subscription_array(indx).cof_trans_id_flag  := 'U';
      px_subscription_array(indx).subscription_error := SUBSTR('Action: ' || lc_action || 'SQLCODE: ' || SQLCODE || ' SQLERRM: ' || SQLERRM, 1, gc_max_sub_err_size);

      lc_action := 'Calling update_subscription_info to update with error info';

      update_subscription_info(px_subscription_info => px_subscription_array(indx));
    END LOOP;

    exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => TRUE);
    RAISE_APPLICATION_ERROR(-20101, 'PROCEDURE: ' || lc_procedure_name || ' Action: ' || lc_action || ' SQLCODE: ' || SQLCODE || ' SQLERRM: ' || SQLERRM);

  END get_cc_trans_id_information;

  /******************************************
  * Helper procedure to process authorization
  ******************************************/

  PROCEDURE process_authorization(p_program_setups      IN            gt_translation_values,
                                  p_contract_info       IN            xx_ar_contracts%ROWTYPE,
                                  px_subscription_array IN OUT NOCOPY subscription_table)
  IS

    lc_procedure_name    CONSTANT  VARCHAR2(61) := gc_package_name || '.' || 'process_authorization';

    lt_parameters                  gt_input_parameters;

    lc_action                      VARCHAR2(1000);

    lc_error                       VARCHAR2(1000);

    lc_decrypted_value             xx_ar_contracts.card_token%TYPE;

    lc_encrypted_value             xx_ar_contracts.card_token%TYPE;

    ln_loop_counter                NUMBER := 0;

    lc_key_label                   xx_ar_contracts.card_encryption_label%TYPE;

    lr_order_header_info           oe_order_headers_all%ROWTYPE;

    lr_invoice_header_info         ra_customer_trx_all%ROWTYPE;

    ln_invoice_total_amount_info   ra_customer_trx_lines_all.extended_amount%TYPE;

    lr_bill_to_cust_acct_site_info hz_cust_acct_sites_all%ROWTYPE;

    lr_bill_to_cust_location_info  hz_locations%ROWTYPE;

    lc_billing_application_id      xx_ar_contracts.payment_identifier%TYPE;

    lc_wallet_id                   xx_ar_contracts.payment_identifier%TYPE;

    lc_auth_payload                VARCHAR2(32000);

    lr_subscription_error_info     xx_ar_subscriptions_error%ROWTYPE;

    lc_auth_completed_flag         xx_ar_subscriptions.auth_completed_flag%TYPE;
    
    lc_email_Sent_flag             xx_ar_subscriptions.email_sent_flag%TYPE;

    lc_authorization_error         xx_ar_subscriptions.authorization_error%TYPE;

    lc_expiration_date             VARCHAR2(4);

    l_request                      UTL_HTTP.req;

    l_response                     UTL_HTTP.resp;

    lclob_buffer                   CLOB;

    lc_buffer                      VARCHAR2(10000);

    lr_subscription_payload_info   xx_ar_subscription_payloads%ROWTYPE;

    lr_subscription_info           xx_ar_subscriptions%ROWTYPE;

    le_skip                        EXCEPTION;

    le_processing                  EXCEPTION;
    
    le_card_failure                EXCEPTION;
    
    le_undefined_failure           EXCEPTION;
    
    lr_contract_line_info          xx_ar_contract_lines%ROWTYPE;
    
    lc_last_auth_attempt_date      DATE;
    
    lc_payment_status              xx_ar_subscriptions.payment_status%TYPE;

    lc_contract_status             xx_ar_subscriptions.contract_status%TYPE;

    lc_next_retry_day              xx_ar_subscriptions.next_retry_day%TYPE;

    l_day                          NUMBER;

    lc_history_sent_flag           xx_ar_subscriptions.history_sent_flag%TYPE;
    
    lr_pos_ordt_info               xx_ar_order_receipt_dtl%ROWTYPE;
    
    lr_pos_info                    xx_ar_pos_inv_order_ref%ROWTYPE;
    
    lr_customer_info               hz_cust_accounts%ROWTYPE;
    
    lr_inv_pymt_sch_info           ar_payment_schedules_all%ROWTYPE;
    
  BEGIN

    entering_sub(p_procedure_name  => lc_procedure_name,
                 p_parameters      => lt_parameters);

    /***********************************************************************************
    * Validate we have all the information in subscriptions needed to create the invoice
    ***********************************************************************************/

    lc_action := 'Looping thru subscription array for prevalidation';

    FOR indx IN 1 .. px_subscription_array.COUNT
    LOOP

      /*****************************
      * Validate invoice was created
      *****************************/
      IF px_subscription_array(indx).invoice_created_flag != 'Y'
      THEN

        lc_error := 'Invoice not created';
        RAISE le_skip;

      END IF;

      /*************************************
      * Validate we are read to perform auth
      *************************************/
      IF px_subscription_array(indx).auth_completed_flag NOT IN ('E','U','N') 
      THEN
        lc_error := 'Auth completed flag: ' || px_subscription_array(indx).auth_completed_flag;
        RAISE le_skip;
      END IF;
 
      /*************************************
      * Validate we are read to perform auth
      *************************************/
      IF p_contract_info.payment_type = 'AB'
      THEN
        lc_error := 'Payment Type is: ' || p_contract_info.payment_type;
        RAISE le_skip;
      END IF;

      /*************************************
      * Validate INVOICE status - OPEN/CLOSE
      *************************************/
      IF px_subscription_array(indx).invoice_number IS NOT NULL
      THEN
        /************************
        * Get invoice information
        ************************/
        
        lc_action := 'Calling get_invoice_header_info';
        
        get_invoice_header_info(p_invoice_number      => px_subscription_array(indx).invoice_number,
                                x_invoice_header_info => lr_invoice_header_info);
         /*****************************************
        * Get invoice payment schedule information
        *****************************************/
       lc_action := 'Calling get_payment_sch_info';
        
        get_payment_sch_info(p_cust_trx_id       => lr_invoice_header_info.customer_trx_id,
                             x_payment_sch_info  => lr_inv_pymt_sch_info);
                             
         IF lr_inv_pymt_sch_info.status = 'CL'
         THEN
           lc_error := 'INVOICE status is closed ';
           RAISE le_skip;
         END IF;
       END IF;
 
    END LOOP;

    lc_action := 'Setting transaction savepoint';

    SAVEPOINT sp_transaction;

    /***********************************************************************
    * Loop thru all the information in subscriptions for interfacing invoice
    ***********************************************************************/

    lc_action := 'Looping thru subscription array for authorization';

    FOR indx IN 1 .. px_subscription_array.COUNT
    LOOP
      BEGIN

        /******************************
        * Get contract line information
        ******************************/

        lc_action := 'Calling get_contract_line_info at process_authorization :';

        get_contract_line_info(p_contract_id          => px_subscription_array(indx).contract_id,
                               p_contract_line_number => px_subscription_array(indx).contract_line_number,
                               x_contract_line_info   => lr_contract_line_info);

        IF  px_subscription_array(indx).billing_sequence_number < lr_contract_line_info.initial_billing_sequence 
        --AND lr_contract_line_info.program = 'SS'
        THEN

          px_subscription_array(indx).auth_completed_flag := 'Y';
          
        ELSIF px_subscription_array(indx).billing_sequence_number >= lr_contract_line_info.initial_billing_sequence
        THEN
        
          /*****************************************************
          * Get day information when do we need to authorization
          *****************************************************/
          
          lc_action := 'Calling get_auth_day_info';
          
          l_day := TO_DATE(TO_CHAR(SYSDATE,'DD-MON-YYYY')||'00:00:00','DD-MON-YYYY HH24:MI:SS') 
                  - NVL(TO_DATE(px_subscription_array(indx).initial_auth_attempt_date,'DD-MON-YYYY HH24:MI:SS')
                        ,TO_DATE(TO_CHAR(SYSDATE,'DD-MON-YYYY')||'00:00:00','DD-MON-YYYY HH24:MI:SS'));
 
          get_auth_day_info(p_auth_day => l_day);
          
          --payment authorization should be done according to the days mentioned in translation
          IF l_day >= 0
             OR (TRUNC(p_contract_info.payment_last_update_date) >= TRUNC(px_subscription_array(indx).last_auth_attempt_date) )
             OR (px_subscription_array(indx).auth_completed_flag = 'U')
          THEN

            IF ln_loop_counter = 0
            THEN
            
              ln_loop_counter := ln_loop_counter + 1;
            
              /**********************************
              *  Decrypt card except for 'PAYPAL'
              **********************************/
            
              IF p_contract_info.card_type != 'PAYPAL'
              THEN
            
                /**************
                * Decrypt Value
                **************/
            
                lc_action := 'Calling decrypt_credit_card';
            
                decrypt_credit_card(p_context_namespace => 'XX_AR_SUBSCRIPTIONS_MT_CTX',
                                    p_context_attribute => 'TYPE',
                                    p_context_value     => 'OM',
                                    p_module            => 'HVOP',
                                    p_format            => 'EBCDIC',
                                    p_encrypted_value   => p_contract_info.card_token,
                                    p_key_label         => p_contract_info.card_encryption_label,
                                    x_decrypted_value   => lc_decrypted_value);
            
                /**************
                * Encrypt Value
                **************/
            
                lc_action := 'Calling encrypt_credit_card';
            
                encrypt_credit_card(p_context_namespace => 'XX_AR_SUBSCRIPTIONS_MT_CTX',
                                    p_context_attribute => 'TYPE',
                                    p_context_value     => 'OM',
                                    p_module            => 'AJB',
                                    p_algorithm         => '3DES',
                                    p_decrypted_value   => lc_decrypted_value,
                                    x_encrypted_value   => lc_encrypted_value,
                                    x_key_label         => lc_key_label);
            
                /*************************************************************************
                * update the settlement_card, settlement_label and settlement_cc_mask     
                * to subscription table, so that even if card authorization fails we will 
                * able to capture card details for sending email for unsuccessful payments
                *************************************************************************/
            
                lc_action := 'Updating credit card details';
            
                IF (lc_decrypted_value IS NOT NULL AND lc_encrypted_value IS NOT NULL AND lc_key_label IS NOT NULL)
                THEN
            
                  px_subscription_array(indx).settlement_card     := lc_encrypted_value;
                  px_subscription_array(indx).settlement_label    := lc_key_label;
                  px_subscription_array(indx).settlement_cc_mask  := SUBSTR(lc_decrypted_value, 1, 6) || SUBSTR(lc_decrypted_value, LENGTH(lc_decrypted_value) - 3, 4);
            
                  lc_action := 'Calling update_subscription_info';
            
                  update_subscription_info(px_subscription_info => px_subscription_array(indx));
            
                END IF;
            
              END IF;
            
              /******************************
              * Get initial order header info
              ******************************/
            
              lc_action := 'Calling get_order_header_info';
            
              IF p_contract_info.external_source = 'POS'
              THEN
                get_pos_ordt_info(p_order_number => p_contract_info.initial_order_number,
                      x_ordt_info    => lr_pos_ordt_info);
                      
                get_pos_info(p_header_id        => lr_pos_ordt_info.header_id,
                             p_orig_sys_doc_ref => p_contract_info.initial_order_number,
                             x_pos_info         => lr_pos_info);
                             
                get_order_header_info(--p_order_number      => lr_pos_info.sales_order,            --Commented for NAIT-126620.
                                      p_order_number      => p_contract_info.initial_order_number, --Added for NAIT-126620
                                      x_order_header_info => lr_order_header_info);
              ELSE
                get_order_header_info(p_order_number      => p_contract_info.initial_order_number,
                                      x_order_header_info => lr_order_header_info);
              END IF;
            
              /*************************************************
              * Get initial order BILL_TO cust account site info
              *************************************************/
            
              lc_action := 'Calling get_cust_account_site_info for BILL_TO';
            
              IF p_contract_info.external_source = 'POS'
              THEN
                get_customer_pos_info(p_aops           => p_contract_info.bill_to_osr,
                                      x_customer_info  => lr_customer_info);
                                    
                get_cust_site_pos_info(p_customer_id     => lr_customer_info.cust_account_id,
                                       x_cust_site_info  => lr_bill_to_cust_acct_site_info);
              ELSE
                get_cust_account_site_info(p_site_use_id            => lr_order_header_info.invoice_to_org_id,
                                           p_site_use_code          => 'BILL_TO',
                                           x_cust_account_site_info => lr_bill_to_cust_acct_site_info);
              END IF;
            
              /***********************************
              * Get initial order BILL_TO location
              ***********************************/
            
              lc_action := 'Calling get_cust_location_info for BILL_TO';
            
              get_cust_location_info(p_cust_acct_site_id  => lr_bill_to_cust_acct_site_info.cust_acct_site_id,
                                     x_cust_location_info => lr_bill_to_cust_location_info);
            
              /************************
              * Get invoice information
              ************************/
              lc_action := 'Calling get_invoice_header_info';
            
              get_invoice_header_info(p_invoice_number      => px_subscription_array(indx).invoice_number,
                                      x_invoice_header_info => lr_invoice_header_info);
            
              /******************************
              * Get invoice total information
              ******************************/
            
              lc_action := 'Calling get_invoice_total_amount_info';
            
              get_invoice_total_amount_info(p_customer_trx_id           => lr_invoice_header_info.customer_trx_id,
                                            x_invoice_total_amount_info => ln_invoice_total_amount_info);
              /**********************************************************************
              * If paypal, pass billing application id, if masterpass, pass wallet id
              **********************************************************************/
            
              IF p_contract_info.card_type = 'PAYPAL'
              THEN
                 lc_billing_application_id := p_contract_info.payment_identifier;
              ELSE
                 lc_wallet_id              := p_contract_info.payment_identifier;
              END IF;

              /***********************
              * Format expiration date
              ***********************/
            
              IF p_contract_info.card_expiration_date IS NOT NULL
              THEN
                lc_expiration_date := TO_CHAR(p_contract_info.card_expiration_date, 'YYMM');
              END IF;

              /****************************
              * Build authorization payload
              ****************************/
            
              lc_action := 'Building authorization payload';
            
              SELECT    '{
                  "paymentAuthorizationRequest": {
                  "transactionHeader": {
                  "consumerName": "EBS",
                  "consumerTransactionId": "'
                             || p_contract_info.contract_number
                             || '-'
                             || TO_CHAR(SYSDATE,
                                        'DDMONYYYYHH24MISS')
                             || '",
                  "consumerTransactionDateTime":"'
                             || TO_CHAR(SYSDATE,
                                        'YYYY-MM-DD')
                             || 'T'
                             || TO_CHAR(SYSDATE,
                                        'HH24:MI:SS')
                             || '"
                    },
                  "customer": {
                  "firstName": "'
                             || p_contract_info.card_holder_name
                             || '",
                  "middleName": "",
                  "lastName": "",
                  "paymentDetails": {
                  "paymentType": "'
                             || p_contract_info.payment_type
                             || '",
                  "paymentCard": {
                  "cardHighValueToken": "'
                             || lc_decrypted_value
                             || '",
                  "expirationDate": "'
                             || lc_expiration_date
                             || '",
                  "amount": "'
                             || ln_invoice_total_amount_info                   
                             || '",
                  "cardType": "'
                             || p_contract_info.card_type
                             || '",
                  "applicationTransactionNumber": "'
                             || px_subscription_array(indx).invoice_number
                             || '",
                  "billingAddress": {
                  "name": "'
                             || p_contract_info.card_holder_name
                             || '",
                  "address": {
                  "address1": "'
                             || lr_bill_to_cust_location_info.address1
                             || '",
                  "address2": "'
                             || lr_bill_to_cust_location_info.address2
                             || '",
                  "city": "'
                             || lr_bill_to_cust_location_info.city
                             || '",
                  "state": "'
                             || lr_bill_to_cust_location_info.state
                             || '",
                  "postalCode": "'
                             || SUBSTR(lr_bill_to_cust_location_info.postal_code, 1, 5)
                             || '",
                  "country": "'
                             || lr_bill_to_cust_location_info.country
                             || '"
                  }
                  }
                  },
                  "billingAgreementId": "'
                             || lc_billing_application_id
                             || '",
                  "walletId": "'
                             || lc_wallet_id
                             || '",
                  "avsOnly": false
                  },
                  "contact": {
                  "email": "'
                             || p_contract_info.customer_email
                             || '",
                  "phoneNumber": "'
                           --  || lv_phone_number --??
                             || '",
                  "faxNumber": "'
                            -- || lv_fax_number --??
                             || '"
                  }
                  },
                "storeNumber": "'
                             || p_contract_info.store_number
                             || '",
                "contract": {
                    "contractId": "'
                             || p_contract_info.contract_id
                             || '",
                    "customerId": "'
                             || p_contract_info.bill_to_osr
                             || '",
                    "cofTransactionId": "'
                             || p_contract_info.cc_trans_id
                             || '"
                  }
                  }
                  }
                  '
              INTO   lc_auth_payload
              FROM   DUAL;
            
              lc_action := 'Validating Wallet location';
            
              IF p_program_setups('wallet_location') IS NOT NULL
              THEN
            
                lc_action := 'calling UTL_HTTP.set_wallet';
            
                UTL_HTTP.SET_WALLET(p_program_setups('wallet_location'), p_program_setups('wallet_password'));
            
              END IF;
              
              lc_action := 'Calling UTL_HTTP.begin_request';
            
              l_request := UTL_HTTP.begin_request(p_program_setups('auth_service_url'), 'POST', ' HTTP/1.1');
            
              lc_action := 'Calling UTL_HTTP.set_header';
            
              UTL_HTTP.set_header(l_request, 'user-agent', 'mozilla/4.0');
            
              UTL_HTTP.set_header(l_request, 'content-type', 'application/json');
            
              UTL_HTTP.set_header(l_request, 'Content-Length', LENGTH(lc_auth_payload));
            
              UTL_HTTP.set_header(l_request, 'Authorization', 'Basic ' || UTL_RAW.cast_to_varchar2(UTL_ENCODE.base64_encode(UTL_RAW.cast_to_raw(p_program_setups('auth_service_user')
                                                                                                                                                || ':' ||
                                                                                                                                                p_program_setups('auth_service_pwd')
                                                                                                                                                ))));
              lc_action := 'Calling UTL_HTTP.write_text';
            
              UTL_HTTP.write_text(l_request, lc_auth_payload);
            
              lc_action := 'Calling UTL_HTTP.get_response';
            
              l_response := UTL_HTTP.get_response(l_request);
            
              COMMIT;
            
              logit(p_message => 'Response status_code' || l_response.status_code);
            
              BEGIN
                lclob_buffer := EMPTY_CLOB;
                LOOP
                  UTL_HTTP.read_text(l_response, lc_buffer, LENGTH(lc_buffer));
                  lclob_buffer := lclob_buffer || lc_buffer;
                END LOOP;
            
                logit(p_message => 'Response Clob: ' || lclob_buffer);
            
                UTL_HTTP.end_response(l_response);
            
              EXCEPTION
              WHEN UTL_HTTP.end_of_body
              THEN
                 UTL_HTTP.end_response(l_response);
              END;
            
              /*********************
              * Masking credit card
              ********************/
            
              IF lc_decrypted_value IS NOT NULL
              THEN
                lc_action := 'Masking credit card';
            
                lc_auth_payload := REPLACE(lc_auth_payload, lc_decrypted_value, SUBSTR(lc_decrypted_value, 1, 6) || '*****' || SUBSTR(lc_decrypted_value, LENGTH(lc_decrypted_value) - 4, 4));
              END IF;
            
              /***********************
              * Store request/response
              ***********************/
            
              lc_action := 'Store request/response';
            
              lr_subscription_payload_info.payload_id              := xx_ar_subscription_payloads_s.NEXTVAL;
              lr_subscription_payload_info.response_data           := lclob_buffer;
              lr_subscription_payload_info.creation_date           := SYSDATE;
              lr_subscription_payload_info.created_by              := FND_GLOBAL.USER_ID;
              lr_subscription_payload_info.last_updated_by         := FND_GLOBAL.USER_ID;
              lr_subscription_payload_info.last_update_date        := SYSDATE;
              lr_subscription_payload_info.input_payload           := lc_auth_payload;
              lr_subscription_payload_info.contract_number         := px_subscription_array(indx).contract_number;
              lr_subscription_payload_info.billing_sequence_number := px_subscription_array(indx).billing_sequence_number;
              lr_subscription_payload_info.contract_line_number    := NULL;
              lr_subscription_payload_info.source                  := lc_procedure_name;
            
              lc_action := 'Calling insert_subscription_payload_info';
            
              insert_subscript_payload_info(p_subscription_payload_info => lr_subscription_payload_info);
            
              /*************************
              * Get response into a CLOB
              *************************/
            
              IF (l_response.status_code != 200)
              THEN
                lc_error := 'Failed response status_code: ' || l_response.status_code;
                RAISE le_processing;
              END IF;
            
              -- updating initial_auth_attempt_date with SYSDATE when auth is done on DAY 1
              IF px_subscription_array(indx).initial_auth_attempt_date IS NULL
              THEN
              
                px_subscription_array(indx).initial_auth_attempt_date := TO_DATE(TO_CHAR(SYSDATE,'DD-MON-YYYY')||'00:00:00','DD-MON-YYYY HH24:MI:SS');
              
              END IF;
  
              /**********************************
              * Get the authorization information
              **********************************/
            
              lr_subscription_info := px_subscription_array(indx);
            
              lc_action := 'Calling retrieve_auth_response_info';
            
              retrieve_auth_response_info(p_payload_id            => lr_subscription_payload_info.payload_id,
                                          px_ar_subscription_info => lr_subscription_info);
            

              /**********************************************************
              * If authorizaiton passed, record authorization information
              **********************************************************/
            
              IF (lr_subscription_info.auth_status = '0')
              THEN
                
                lc_action := 'assigning the auth success result to subscription array';
                
                px_subscription_array(indx)                         := lr_subscription_info;
                px_subscription_array(indx).auth_completed_flag     := 'Y';
                px_subscription_array(indx).email_sent_flag         := 'N';
                px_subscription_array(indx).history_sent_flag       := 'N';
                px_subscription_array(indx).last_auth_attempt_date  := SYSDATE;
                px_subscription_array(indx).payment_status          := 'SUCCESS';
                px_subscription_array(indx).contract_status         := NULL;
                px_subscription_array(indx).next_retry_day          := NULL;
                
                IF p_contract_info.cc_trans_id IS NULL
                THEN
                  --call update contracts table with cc_trans_id and cc_trans_id_source
                  update_contracts_info(p_contract_id           => px_subscription_array(indx).contract_id
                                       ,p_cc_trans_id           => lr_subscription_info.cof_trans_id
                                       ,p_cc_trans_id_source    => 'EBS'
                                       ,p_cof_trans_id_scm_flag => 'N'
                                       );
                END IF;
              ELSIF lr_subscription_info.auth_status IS NOT NULL
              THEN
                lc_action := 'assigning the auth failure result to subscription array';
                
                px_subscription_array(indx)                         := lr_subscription_info;
                px_subscription_array(indx).auth_status             := lr_subscription_info.auth_status;
                px_subscription_array(indx).auth_message            := lr_subscription_info.auth_message;
                px_subscription_array(indx).last_auth_attempt_date  := SYSDATE;
                px_subscription_array(indx).payment_status          := 'FAILURE';
                px_subscription_array(indx).contract_status         := NULL;
                px_subscription_array(indx).next_retry_day          := NULL;
                RAISE le_card_failure;
              ELSE
                lc_action := 'assigning the auth failure result to subscription array';
                
                px_subscription_array(indx)                     := lr_subscription_info;
                px_subscription_array(indx).auth_status         := lr_subscription_info.auth_status;
                px_subscription_array(indx).auth_message        := lr_subscription_info.auth_message;
                RAISE le_undefined_failure;
              END IF;
            
            ELSE
            
              /**********************************
              * Get the authorization information
              **********************************/
            
              lr_subscription_info := px_subscription_array(indx);
            
              lc_action := 'Calling retrieve_auth_response_info';
            
              retrieve_auth_response_info(p_payload_id            => lr_subscription_payload_info.payload_id,
                                          px_ar_subscription_info => lr_subscription_info);
                         
              /**********************************************************
              * If authorization passed, record authorization information
              **********************************************************/
            
              IF (lr_subscription_info.auth_status = '0')
              THEN
                px_subscription_array(indx)                         := lr_subscription_info;
                px_subscription_array(indx).auth_completed_flag     := 'Y';
                px_subscription_array(indx).email_sent_flag         := 'N';
                px_subscription_array(indx).history_sent_flag       := 'N';
                px_subscription_array(indx).last_auth_attempt_date  := SYSDATE;
                px_subscription_array(indx).payment_status          := 'SUCCESS';
                px_subscription_array(indx).contract_status         := NULL;
                px_subscription_array(indx).next_retry_day          := NULL;
                
                IF p_contract_info.cc_trans_id IS NULL
                THEN
                  --call update contracts table with cc_trans_id and cc_trans_id_source
                  update_contracts_info(p_contract_id           => px_subscription_array(indx).contract_id
                                       ,p_cc_trans_id           => lr_subscription_info.cof_trans_id
                                       ,p_cc_trans_id_source    => 'EBS'
                                       ,p_cof_trans_id_scm_flag => 'N'
                                       );
                END IF;

              END IF;
            
              lc_action := 'Updating credit card details';
            
              px_subscription_array(indx).settlement_card     := lc_encrypted_value;
              px_subscription_array(indx).settlement_label    := lc_key_label;
              px_subscription_array(indx).settlement_cc_mask  := SUBSTR(lc_decrypted_value, 1, 6) || SUBSTR(lc_decrypted_value, LENGTH(lc_decrypted_value) - 3, 4);
  
              -- updating initial_auth_attempt_date with SYSDATE when auth is done on DAY 1
              IF px_subscription_array(indx).initial_auth_attempt_date IS NULL
              THEN
              
                px_subscription_array(indx).initial_auth_attempt_date := TO_DATE(TO_CHAR(SYSDATE,'DD-MON-YYYY')||'00:00:00','DD-MON-YYYY HH24:MI:SS');
              
              END IF;
            
            END IF; -- IF ln_loop_counter = 0
          END IF; 
        END IF; -- IF px_subscription_array(indx).billing_sequene_number != 1

        lc_action := 'Calling update_subscription_info';

        update_subscription_info(px_subscription_info => px_subscription_array(indx));

      EXCEPTION
      WHEN le_processing
      THEN

        lr_subscription_error_info                         := NULL;
        lr_subscription_error_info.contract_id             := px_subscription_array(indx).contract_id;
        lr_subscription_error_info.contract_number         := px_subscription_array(indx).contract_number;
        lr_subscription_error_info.contract_line_number    := NULL;
        lr_subscription_error_info.billing_sequence_number := px_subscription_array(indx).billing_sequence_number;
        lr_subscription_error_info.error_module            := lc_procedure_name;
        lr_subscription_error_info.error_message           := SUBSTR('Action: ' || lc_action || ' Error: ' || lc_error, 1, gc_max_err_size);
        lr_subscription_error_info.creation_date           := SYSDATE;

        lc_action := 'Calling insert_subscription_error_info';

        insert_subscription_error_info(p_subscription_error_info => lr_subscription_error_info);
       
        lc_auth_completed_flag := 'U';
        lc_authorization_error := SUBSTR(lr_subscription_error_info.error_message, 1, gc_max_sub_err_size);

        RAISE le_processing;
        
      WHEN le_undefined_failure
      THEN

        lr_subscription_error_info                         := NULL;
        lr_subscription_error_info.contract_id             := px_subscription_array(indx).contract_id;
        lr_subscription_error_info.contract_number         := px_subscription_array(indx).contract_number;
        lr_subscription_error_info.contract_line_number    := NULL;
        lr_subscription_error_info.billing_sequence_number := px_subscription_array(indx).billing_sequence_number;
        lr_subscription_error_info.error_module            := lc_procedure_name;
        lr_subscription_error_info.error_message           := SUBSTR('Action: ' || lc_action || ' Error: ' || lc_error, 1, gc_max_err_size);
        lr_subscription_error_info.creation_date           := SYSDATE;

        lc_action := 'Calling insert_subscription_error_info';

        insert_subscription_error_info(p_subscription_error_info => lr_subscription_error_info);

        lc_auth_completed_flag := 'U';
        lc_authorization_error := SUBSTR(lr_subscription_error_info.error_message, 1, gc_max_sub_err_size);

        RAISE le_undefined_failure;
       
      WHEN le_card_failure
      THEN

        lr_subscription_error_info                         := NULL;
        lr_subscription_error_info.contract_id             := px_subscription_array(indx).contract_id;
        lr_subscription_error_info.contract_number         := px_subscription_array(indx).contract_number;
        lr_subscription_error_info.contract_line_number    := NULL;
        lr_subscription_error_info.billing_sequence_number := px_subscription_array(indx).billing_sequence_number;
        lr_subscription_error_info.error_module            := lc_procedure_name;
        lr_subscription_error_info.error_message           := SUBSTR('Action: ' || lc_action || ' Error: ' || lc_error, 1, gc_max_err_size);
        lr_subscription_error_info.creation_date           := SYSDATE;

        lc_action := 'Calling insert_subscription_error_info';

        insert_subscription_error_info(p_subscription_error_info => lr_subscription_error_info);

        lc_last_auth_attempt_date := SYSDATE;
        lc_payment_status         := 'FAILURE';
        lc_auth_completed_flag    := 'E';
        lc_email_Sent_flag        := 'N';
        lc_history_sent_flag      := 'N';
        lc_contract_status        := NULL;
        lc_next_retry_day         := NULL;
        lc_authorization_error    := SUBSTR(lr_subscription_error_info.error_message, 1, gc_max_sub_err_size);

        RAISE le_card_failure;

      WHEN OTHERS
      THEN

        lr_subscription_error_info                         := NULL;
        lr_subscription_error_info.contract_id             := px_subscription_array(indx).contract_id;
        lr_subscription_error_info.contract_number         := px_subscription_array(indx).contract_number;
        lr_subscription_error_info.contract_line_number    := NULL;
        lr_subscription_error_info.billing_sequence_number := px_subscription_array(indx).billing_sequence_number;
        lr_subscription_error_info.error_module            := lc_procedure_name;
        lr_subscription_error_info.error_message           := SUBSTR('Action: ' || lc_action || ' Error: ' || SQLCODE || ' ' || SQLERRM, 1, gc_max_err_size);
        lr_subscription_error_info.creation_date           := SYSDATE;

        lc_action := 'Calling insert_subscription_error_info';

        insert_subscription_error_info(p_subscription_error_info => lr_subscription_error_info);

        lc_auth_completed_flag := 'U';
        lc_authorization_error := SUBSTR(lr_subscription_error_info.error_message, 1, gc_max_sub_err_size);

        RAISE le_processing;

      END;

    END LOOP;

    exiting_sub(p_procedure_name => lc_procedure_name);

  EXCEPTION
  WHEN le_skip
  THEN
    logit(p_message => 'Skipping: ' || lc_error);

  WHEN le_processing
  THEN

    FOR indx IN 1 .. px_subscription_array.COUNT
    LOOP

      px_subscription_array(indx).auth_completed_flag := lc_auth_completed_flag;
      px_subscription_array(indx).authorization_error := lc_authorization_error;

      lc_action := 'Calling update_subscription_info to update with error info';

      update_subscription_info(px_subscription_info => px_subscription_array(indx));

    END LOOP;

    exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => TRUE);
    RAISE_APPLICATION_ERROR(-20101, lc_authorization_error);
  
  WHEN le_undefined_failure
  THEN

    FOR indx IN 1 .. px_subscription_array.COUNT
    LOOP
      
      /**********************************
      * Get the authorization information
      **********************************/

      lr_subscription_info := px_subscription_array(indx);

      lc_action := 'Calling retrieve_auth_response_info';

      retrieve_auth_response_info(p_payload_id            => lr_subscription_payload_info.payload_id,
                                  px_ar_subscription_info => lr_subscription_info);
      
      px_subscription_array(indx)                     := lr_subscription_info;

      px_subscription_array(indx).auth_completed_flag := lc_auth_completed_flag;
      px_subscription_array(indx).authorization_error := lc_authorization_error;
      
      lc_action := 'Updating credit card details';

      px_subscription_array(indx).settlement_card     := lc_encrypted_value;
      px_subscription_array(indx).settlement_label    := lc_key_label;
      px_subscription_array(indx).settlement_cc_mask  := SUBSTR(lc_decrypted_value, 1, 6) || SUBSTR(lc_decrypted_value, LENGTH(lc_decrypted_value) - 3, 4);

      lc_action := 'Calling update_subscription_info to update with error info';

      update_subscription_info(px_subscription_info => px_subscription_array(indx));

    END LOOP;

    exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => TRUE);
    RAISE_APPLICATION_ERROR(-20101, lc_authorization_error);

  WHEN le_card_failure
  THEN

    FOR indx IN 1 .. px_subscription_array.COUNT
    LOOP
    
      /**********************************
      * Get the authorization information
      **********************************/

      lr_subscription_info := px_subscription_array(indx);

      lc_action := 'Calling retrieve_auth_response_info';

      retrieve_auth_response_info(p_payload_id            => lr_subscription_payload_info.payload_id,
                                  px_ar_subscription_info => lr_subscription_info);
      
      px_subscription_array(indx)                           := lr_subscription_info;
 
      -- updating initial_auth_attempt_date with SYSDATE when auth is done on DAY 1
      IF px_subscription_array(indx).initial_auth_attempt_date IS NULL
      THEN
      
        px_subscription_array(indx).initial_auth_attempt_date := TO_DATE(TO_CHAR(SYSDATE,'DD-MON-YYYY')||'00:00:00','DD-MON-YYYY HH24:MI:SS');
      
      END IF;

      px_subscription_array(indx).last_auth_attempt_date    := lc_last_auth_attempt_date;
      px_subscription_array(indx).payment_status            := lc_payment_status;
      px_subscription_array(indx).contract_status           := lc_contract_status;
      px_subscription_array(indx).next_retry_day            := lc_next_retry_day;
      px_subscription_array(indx).auth_completed_flag       := lc_auth_completed_flag;
      px_subscription_array(indx).email_sent_flag           := lc_email_Sent_flag;
      px_subscription_array(indx).history_sent_flag         := lc_history_sent_flag;
      px_subscription_array(indx).authorization_error       := lc_authorization_error;
      
      lc_action := 'Updating credit card details';

      px_subscription_array(indx).settlement_card     := lc_encrypted_value;
      px_subscription_array(indx).settlement_label    := lc_key_label;
      px_subscription_array(indx).settlement_cc_mask  := SUBSTR(lc_decrypted_value, 1, 6) || SUBSTR(lc_decrypted_value, LENGTH(lc_decrypted_value) - 3, 4);
      
      lc_action := 'Calling update_subscription_info to update with error info';

      update_subscription_info(px_subscription_info => px_subscription_array(indx));

    END LOOP;

    exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => TRUE);
    RAISE_APPLICATION_ERROR(-20101, lc_authorization_error);

  WHEN OTHERS
  THEN

    FOR indx IN 1 .. px_subscription_array.COUNT
    LOOP

      px_subscription_array(indx).auth_completed_flag := 'E';
      px_subscription_array(indx).authorization_error := SUBSTR('Action: ' || lc_action || 'SQLCODE: ' || SQLCODE || ' SQLERRM: ' || SQLERRM, 1, gc_max_sub_err_size);

      lc_action := 'Calling update_subscription_info to update with error info';

      update_subscription_info(px_subscription_info => px_subscription_array(indx));
    END LOOP;

    exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => TRUE);
    RAISE_APPLICATION_ERROR(-20101, 'PROCEDURE: ' || lc_procedure_name || ' Action: ' || lc_action || ' SQLCODE: ' || SQLCODE || ' SQLERRM: ' || SQLERRM);

  END process_authorization;

  /***************************************
  * Helper procedure to send billing email
  ***************************************/

  PROCEDURE send_billing_email(p_program_setups      IN            gt_translation_values,
                               p_contract_info       IN            xx_ar_contracts%ROWTYPE,
                               px_subscription_array IN OUT NOCOPY subscription_table)
  IS

    lc_procedure_name    CONSTANT  VARCHAR2(61) := gc_package_name || '.' || 'send_billing_email';

    lt_parameters                  gt_input_parameters;

    lc_action                      VARCHAR2(1000);

    lc_error                       VARCHAR2(1000);

    ln_loop_counter                NUMBER := 0;

    lr_invoice_header_info         ra_customer_trx_all%ROWTYPE;

    ln_invoice_total_amount_info   ra_customer_trx_lines_all.extended_amount%TYPE;

    lc_masked_credit_card_number   xx_ar_subscriptions.settlement_cc_mask%TYPE;

    lc_billing_agreement_id        xx_ar_contracts.payment_identifier%TYPE;
    
    lr_contract_line_info          xx_ar_contract_lines%ROWTYPE;

    lc_wallet_id                   xx_ar_contracts.payment_identifier%TYPE;

    lc_email_payload               VARCHAR2(32000) := NULL;

    lc_card_expiration_date        VARCHAR2(4);

    l_request                      UTL_HTTP.req;

    l_response                     UTL_HTTP.resp;

    lclob_buffer                   CLOB;

    lc_buffer                      VARCHAR2(10000);

    lr_subscription_payload_info   xx_ar_subscription_payloads%ROWTYPE;

    lr_subscription_error_info     xx_ar_subscriptions_error%ROWTYPE;

    lc_email_sent_flag             VARCHAR2(2)  := 'N';

    lc_email_sent_counter          NUMBER := 0;

    lc_email_failed_counter        NUMBER := 0;

    lc_invoice_status              VARCHAR2(30)  := NULL;
    
    lc_failure_message             VARCHAR2(256) := NULL;

    le_skip                        EXCEPTION;

    le_processing                  EXCEPTION;
    
    lr_translation_info            xx_fin_translatevalues%ROWTYPE;
    
    lc_next_retry_date             DATE;
    
    lc_contract_status             xx_ar_subscriptions.contract_status%TYPE;

    lc_next_retry_day              NUMBER;

    lc_day                         NUMBER;

    lc_cancel_date                 DATE;

    lc_reason_code                 VARCHAR2(256) := NULL;
    
    lc_contract_number_modifier    xx_ar_contracts.contract_number_modifier%TYPE;


  BEGIN

    entering_sub(p_procedure_name  => lc_procedure_name,
                 p_parameters      => lt_parameters);

    /***************************************************************************************
    * Validate we have all the information in subscriptions needed to send the billing email
    ***************************************************************************************/

    lc_action := 'Looping thru subscription array for prevalidation';

    FOR indx IN 1 .. px_subscription_array.COUNT
    LOOP

      
      /************************************
      * Validate we are ready to send email
      ************************************/

      IF px_subscription_array(indx).email_sent_flag NOT IN ('N', 'E')
      THEN

        lc_error := 'Email Sent flag: ' || px_subscription_array(indx).email_sent_flag;
        RAISE le_skip;

      END IF;
      
      /***************************
      * Validate for authorization
      ***************************/
      IF px_subscription_array(indx).auth_completed_flag NOT IN ('Y', 'E','T')
      THEN
        lc_error := 'Authorization is not completed';
        RAISE le_skip;
      END IF;

      /***********************************
      * Validate we are read to send email
      ***********************************/
      
      IF p_contract_info.payment_type = 'AB'
      THEN
        lc_error := 'Payment Type is: ' || p_contract_info.payment_type;
        RAISE le_skip;
      END IF;

      /******************************
      * Get contract line information
      ******************************/

      lc_action := 'Calling get_contract_line_info send_billing_email';

      get_contract_line_info(p_contract_id          => px_subscription_array(indx).contract_id,
                             p_contract_line_number => px_subscription_array(indx).contract_line_number,
                             x_contract_line_info   => lr_contract_line_info);
                             
      IF lr_contract_line_info.item_name = p_program_setups('termination_sku')
      THEN 
        lc_error := 'Termination SKU : ' || lr_contract_line_info.item_name;
        RAISE le_skip;
      END IF;      
 
    END LOOP;

    lc_action := 'Setting transaction savepoint';

    SAVEPOINT sp_transaction;

    /*****************************************************************
    * Loop thru all the information in subscriptions for sending email
    *****************************************************************/

    lc_action := 'Looping thru subscription array for Email service';

    FOR indx IN 1 .. px_subscription_array.COUNT
    LOOP

      BEGIN
       
        /************************************
        * Get contract line level information
        ************************************/

        lc_action := 'Calling get_contract_line_info send_billing_email2';

        get_contract_line_info(p_contract_id          => px_subscription_array(indx).contract_id,
                               p_contract_line_number => px_subscription_array(indx).contract_line_number,
                               x_contract_line_info   => lr_contract_line_info);

        IF  px_subscription_array(indx).billing_sequence_number < lr_contract_line_info.initial_billing_sequence 
        AND lr_contract_line_info.program = 'SS'
        THEN 

          px_subscription_array(indx).email_sent_flag  := 'Y';
          
        ELSIF px_subscription_array(indx).billing_sequence_number  >= lr_contract_line_info.initial_billing_sequence
          AND lr_contract_line_info.program = 'BS' 
          AND px_subscription_array(indx).auth_completed_flag='Y'
          AND p_contract_info.contract_number_modifier IS NULL
        THEN

          /**************************************************
          * Send contract confirmation email for BS Customers
          **************************************************/

          IF ln_loop_counter = 0
          THEN

            ln_loop_counter := ln_loop_counter + 1;
            
            /*******************************************************
            * getting information of next retry day from translation
            *******************************************************/
            IF px_subscription_array(indx).contract_status IS NULL
            THEN

              lc_action := 'fetching next Retry Day information';
  
              lc_day := TO_DATE(TO_CHAR(SYSDATE,'DD-MON-YYYY')||'00:00:00','DD-MON-YYYY HH24:MI:SS') - NVL(TO_DATE(px_subscription_array(indx).initial_auth_attempt_date,'DD-MON-YYYY HH24:MI:SS')
                                                                                        ,TO_DATE(TO_CHAR(SYSDATE,'DD-MON-YYYY')||'00:00:00','DD-MON-YYYY HH24:MI:SS'));
           
              get_auth_fail_info(p_payment_status    => px_subscription_array(indx).payment_status,
                                 p_auth_day          => lc_day,
                                 px_translation_info => lr_translation_info); 
              
              IF p_contract_info.contract_user_status = 'HOLD' and px_subscription_array(indx).payment_status = 'SUCCESS'
              THEN
                px_subscription_array(indx).contract_status  := 'REMOVE_HOLD';  
                px_subscription_array(indx).next_retry_day   := TO_NUMBER(lr_translation_info.target_value2);
                
                lc_contract_status := 'REMOVE_HOLD';
                lc_next_retry_day  := TO_NUMBER(lr_translation_info.target_value2);
              
              ELSE
                px_subscription_array(indx).contract_status  := lr_translation_info.target_value1;  
                px_subscription_array(indx).next_retry_day   := TO_NUMBER(lr_translation_info.target_value2);
                
                lc_contract_status := lr_translation_info.target_value1;  
                lc_next_retry_day  := TO_NUMBER(lr_translation_info.target_value2);
              
              END IF;

              lc_action := 'Calling update_subscription_info';
              
              update_subscription_info(px_subscription_info => px_subscription_array(indx));

            END IF;
            
            /******************************************
            * Build contract confirmation email payload
            ******************************************/
            lc_action := 'Building contract confirmation email payload';
            
            SELECT '{
                "contractEmailRequest": {
                    "transactionHeader": {
                        "consumer": {
                            "consumerName": "EBS"
                        },
                        "transactionId": "'
                                      || px_subscription_array(indx).contract_number 
                                      || '-' 
                                      || px_subscription_array(indx).initial_order_number 
                                      || '-' 
                                      || px_subscription_array(indx).billing_sequence_number
                                      || '",
                        "timeReceived": null
                    },              
                    "emailNotification": {
                        "orderNumber": "' 
                                      || SUBSTR(px_subscription_array(indx).contract_name,1,9)||SUBSTR(px_subscription_array(indx).contract_name,11,13)
                                      || '",
                        "contractNumber": "' 
                                      || px_subscription_array(indx).contract_number 
                                      || '",
                        "contractId": "'
                                      || px_subscription_array(indx).contract_id
                                      || '",
                        "contractNumberModifier": "'
                                      || p_contract_info.contract_number_modifier
                                      || '",
                        "billToAccountNumber": "' 
                                      || p_contract_info.bill_to_osr 
                                      || '",
                        "storeNumber": "' 
                                      || p_contract_info.store_number 
                                      || '",
                        "rewardsNumber": "'
                                      ||p_contract_info.loyalty_member_number
                                      || '",
                        "emailAddress": "' 
                                      || p_contract_info.customer_email 
                                      || '",
                        "serviceType": "' 
                                      || lr_contract_line_info.program
                                      || '",
                        "contractStatus": "'
                                      || px_subscription_array(indx).contract_status
                                      || '", 
                        "startDate": "' 
                                      || TO_CHAR(px_subscription_array(indx).service_period_start_date,'MM/DD/YYYY')
                                      || '",
                        "endDate": "' 
                                      || TO_CHAR(px_subscription_array(indx).service_period_end_date,'MM/DD/YYYY')
                                      || '",
                        "skuNumber": "' 
                                      || lr_contract_line_info.item_name
                                      || '",
                        "amount": "' 
                                      || px_subscription_array(indx).total_contract_amount
                                      || '"
                    }
                }
            }
            '
            INTO   lc_email_payload
            FROM   DUAL;
            
            lc_action := 'Validating Wallet location';

            IF p_program_setups('wallet_location') IS NOT NULL
            THEN

              lc_action := 'calling UTL_HTTP.set_wallet';

              UTL_HTTP.SET_WALLET(p_program_setups('wallet_location'), p_program_setups('wallet_password'));

            END IF;

            lc_action := 'Calling UTL_HTTP.set_response_error_check';

            UTL_HTTP.set_response_error_check(FALSE);

            lc_action := 'Calling UTL_HTTP.begin_request';

            l_request := UTL_HTTP.begin_request(p_program_setups('bs_email_service_url'), 'POST', ' HTTP/1.1');

            lc_action := 'Calling UTL_HTTP.SET_HEADER: user-agent';

            UTL_HTTP.SET_HEADER(l_request, 'user-agent', 'mozilla/4.0');

            lc_action := 'Calling UTL_HTTP.SET_HEADER: content-type';

            UTL_HTTP.SET_HEADER(l_request, 'content-type', 'application/json');

            lc_action := 'Calling UTL_HTTP.SET_HEADER: Content-Length';

            UTL_HTTP.SET_HEADER(l_request, 'Content-Length', LENGTH(lc_email_payload));

            lc_action := 'Calling UTL_HTTP.SET_HEADER: Authorization';

            UTL_HTTP.SET_HEADER(l_request, 'Authorization', 'Basic ' || UTL_RAW.cast_to_varchar2(UTL_ENCODE.base64_encode(UTL_RAW.cast_to_raw(p_program_setups('bs_email_service_user')
                                                                                                                                              || ':' ||
                                                                                                                                              p_program_setups('bs_email_service_pwd')
                                                                                                                                              ))));
            lc_action := 'Calling UTL_HTTP.write_text';

            UTL_HTTP.write_text(l_request, lc_email_payload);

            lc_action := 'Calling UTL_HTTP.get_response';

            l_response := UTL_HTTP.get_response(l_request);

            COMMIT;

            logit(p_message => 'Response status_code' || l_response.status_code);

            /*************************
            * Get response into a CLOB
            *************************/

            lc_action := 'Getting response';

            BEGIN

              lclob_buffer := EMPTY_CLOB;
              LOOP

                UTL_HTTP.read_text(l_response, lc_buffer, LENGTH(lc_buffer));
                lclob_buffer := lclob_buffer || lc_buffer;

              END LOOP;

              logit(p_message => 'Response Clob: ' || lclob_buffer);

              UTL_HTTP.end_response(l_response);

            EXCEPTION
              WHEN UTL_HTTP.end_of_body
              THEN

                UTL_HTTP.end_response(l_response);

            END;

            /***********************
            * Store request/response
            ***********************/

            lc_action := 'Store request/response';

            lr_subscription_payload_info.payload_id              := xx_ar_subscription_payloads_s.NEXTVAL;
            lr_subscription_payload_info.response_data           := lclob_buffer;
            lr_subscription_payload_info.creation_date           := SYSDATE;
            lr_subscription_payload_info.created_by              := FND_GLOBAL.USER_ID;
            lr_subscription_payload_info.last_updated_by         := FND_GLOBAL.USER_ID;
            lr_subscription_payload_info.last_update_date        := SYSDATE;
            lr_subscription_payload_info.input_payload           := lc_email_payload;
            lr_subscription_payload_info.contract_number         := px_subscription_array(indx).contract_number;
            lr_subscription_payload_info.billing_sequence_number := px_subscription_array(indx).billing_sequence_number;
            lr_subscription_payload_info.contract_line_number    := NULL;
            lr_subscription_payload_info.source                  := lc_procedure_name;

            lc_action := 'Calling insert_subscription_payload_info';

            insert_subscript_payload_info(p_subscription_payload_info => lr_subscription_payload_info);

            IF (l_response.status_code = 200)
            THEN

              lc_email_sent_counter := lc_email_sent_counter + 1;
              
              px_subscription_array(indx).email_sent_flag             := 'Y';
              px_subscription_array(indx).email_sent_date             := SYSDATE;
              --px_subscription_array(indx).contract_status             := 'SUCCESS';
              px_subscription_array(indx).last_update_date            := SYSDATE;
              px_subscription_array(indx).last_updated_by             := FND_GLOBAL.USER_ID;

            ELSE

              lc_action := NULL;

              lc_error  := 'Contract confimraiton email sent failure - response code: ' || l_response.status_code;

              RAISE le_processing;

            END IF;

          ELSE

              px_subscription_array(indx).email_sent_flag             := 'Y';
              px_subscription_array(indx).email_sent_date             := SYSDATE;
              --px_subscription_array(indx).contract_status             := 'SUCCESS';
              px_subscription_array(indx).last_update_date            := SYSDATE;
              px_subscription_array(indx).last_updated_by             := FND_GLOBAL.USER_ID;
              
              IF px_subscription_array(indx).contract_status IS NULL
              THEN
    
                px_subscription_array(indx).contract_status  := lc_contract_status;  
                px_subscription_array(indx).next_retry_day   := lc_next_retry_day;   

               END IF;

          END IF;--ln_loop_counter end if  
          
          /* ** End of Contract Confirmation email ***/
        ELSIF px_subscription_array(indx).billing_sequence_number >= lr_contract_line_info.initial_billing_sequence
        THEN
        
          IF ln_loop_counter = 0 
          THEN

            ln_loop_counter := ln_loop_counter + 1;

            /************************
            * Get invoice information
            ************************/

            lc_action := 'Calling get_invoice_header_info';

            get_invoice_header_info(p_invoice_number      => px_subscription_array(indx).invoice_number,
                                    x_invoice_header_info => lr_invoice_header_info);

            /******************************
            * Get invoice total information
            ******************************/

            lc_action := 'Calling get_invoice_total_amount_info';

            get_invoice_total_amount_info(p_customer_trx_id           => lr_invoice_header_info.customer_trx_id,
                                          x_invoice_total_amount_info => ln_invoice_total_amount_info);

            /***************************************
            * Masking card details except for PAYPAL
            ***************************************/
            lc_action := 'Masking credit card';

            IF p_contract_info.card_type != 'PAYPAL'
            THEN

              IF px_subscription_array(indx).settlement_cc_mask IS NOT NULL
              THEN

                lc_masked_credit_card_number :=  LPAD(SUBSTR(px_subscription_array(indx).settlement_cc_mask, -4), 16, 'x');

              ELSE

                lc_masked_credit_card_number := 'BAD CARD'; 

              END IF;

            ELSE

              lc_masked_credit_card_number := NULL;

            END IF;

            /**********************************************************************
            * If paypal, pass billing application id, if masterpass, pass wallet id
            **********************************************************************/

            IF p_contract_info.card_type = 'PAYPAL'
            THEN

              lc_billing_agreement_id  := p_contract_info.payment_identifier;

            ELSE

              lc_wallet_id             := p_contract_info.payment_identifier;

            END IF;

            /***********************
            * Format expiration date
            ***********************/

            IF p_contract_info.card_expiration_date IS NOT NULL
            THEN

              lc_action := 'Formating card_expiration_date';
  
              lc_card_expiration_date := TO_CHAR(p_contract_info.card_expiration_date, 'YYMM'); 
  
            END IF;
 
            /*******************************************************
            * getting information of next retry day from translation
            *******************************************************/
            IF px_subscription_array(indx).contract_status IS NULL
            THEN

              lc_action := 'fetching next Retry Day information';
  
              lc_day := TO_DATE(TO_CHAR(SYSDATE,'DD-MON-YYYY')||'00:00:00','DD-MON-YYYY HH24:MI:SS') - NVL(TO_DATE(px_subscription_array(indx).initial_auth_attempt_date,'DD-MON-YYYY HH24:MI:SS')
                                                                                        ,TO_DATE(TO_CHAR(SYSDATE,'DD-MON-YYYY')||'00:00:00','DD-MON-YYYY HH24:MI:SS'));
           
              get_auth_fail_info(p_payment_status    => px_subscription_array(indx).payment_status,
                                 p_auth_day          => lc_day,
                                 px_translation_info => lr_translation_info); 
              
              IF p_contract_info.contract_user_status = 'HOLD' and px_subscription_array(indx).payment_status = 'SUCCESS'
              THEN
                px_subscription_array(indx).contract_status  := 'REMOVE_HOLD';  
                px_subscription_array(indx).next_retry_day   := TO_NUMBER(lr_translation_info.target_value2);
                
                lc_contract_status := 'REMOVE_HOLD';
                lc_next_retry_day  := TO_NUMBER(lr_translation_info.target_value2);
              
              ELSE
                px_subscription_array(indx).contract_status  := lr_translation_info.target_value1;  
                px_subscription_array(indx).next_retry_day   := TO_NUMBER(lr_translation_info.target_value2);
                
                lc_contract_status := lr_translation_info.target_value1;  
                lc_next_retry_day  := TO_NUMBER(lr_translation_info.target_value2);
              
              END IF;

              lc_action := 'Calling update_subscription_info';
              
              update_subscription_info(px_subscription_info => px_subscription_array(indx));

            END IF;

            IF px_subscription_array(indx).contract_status = gc_contract_status
            THEN
  
              lc_cancel_date     := NVL(px_subscription_array(indx).NEXT_BILLING_DATE-1,SYSDATE);
              lc_reason_code     := 'TERMINATED_Non-Payment';

            END IF;

            /************************************************
            * Assigning invoice status based on authorization
            ************************************************/
            lc_action := 'Assiging invoice status based on authorizaiton';

            IF px_subscription_array(indx).auth_completed_flag = 'Y'
            THEN

              lc_invoice_status := 'SUCCESS';
              
              lc_failure_message := NULL;
              
              lc_next_retry_date := NULL;

            ELSE

              lc_invoice_status := 'FAILED';
              
              lc_failure_message := px_subscription_array(indx).auth_message;
                                                 
              lc_next_retry_date := NVL(px_subscription_array(indx).initial_auth_attempt_date,SYSDATE) + px_subscription_array(indx).next_retry_day;

            END IF;
            
            IF p_contract_info.contract_number_modifier IS NOT NULL
            THEN
              lc_contract_number_modifier := p_contract_info.contract_number_modifier;
            ELSE
              lc_contract_number_modifier := NULL;
            END IF;

           /********************
            * Build email payload
            ********************/

            lc_action := 'Building email payload';

            SELECT  '{
                "billingStatusEmailRequest": {
                "transactionHeader": {
                "consumer": {
                        "consumerName": "EBS"
                    },
                    "transactionId": "'
                                || px_subscription_array(indx).contract_number
                                || '-'
                                || px_subscription_array(indx).initial_order_number
                                || '-'
                                || px_subscription_array(indx).billing_sequence_number
                                || '",
                    "timeReceived": null
                },
                "customer": {
                        "firstName": "'
                                || p_contract_info.bill_to_customer_name
                                || '",
                        "middleName": null,
                        "lastName": "",
                        "accountNumber": "'
                                || p_contract_info.bill_to_osr
                                || '",
                        "loyaltyNumber": "'
                                || p_contract_info.loyalty_member_number
                                || '",
                        "contact": {
                                "email": "'
                                    || p_contract_info.customer_email
                                    || '",
                                "phoneNumber": "",
                                "faxNumber": ""
                        }
                },
                "invoice": {
                    "invoiceNumber": "'
                                || px_subscription_array(indx).invoice_number
                                || '",
                    "orderNumber": "'
                                || SUBSTR(px_subscription_array(indx).contract_name,1,9)||SUBSTR(px_subscription_array(indx).contract_name,11,13)
                                || '",
                    "serviceContractNumber": "'
                                || px_subscription_array(indx).contract_number
                                || '",
                    "contractId": "'
                                || px_subscription_array(indx).contract_id
                                || '",
                    "contractNumberModifier": "'
                                || lc_contract_number_modifier
                                || '",
                    "billingSequenceNumber": "'
                                || px_subscription_array(indx).billing_sequence_number
                                || '",
                    "initialBillingSequence": "'
                                || lr_contract_line_info.initial_billing_sequence
                                || '",
                    "billingDate": "'
                                || TO_CHAR(px_subscription_array(indx).billing_date,'DD-MON-YYYY HH24:MI:SS')
                                || '",
                    "billingTime": "",
                    "invoiceDate": "'
                                || TO_CHAR(lr_invoice_header_info.trx_date,'DD-MON-YYYY HH24:MI:SS')
                                || '",
                    "invoiceTime": "",
                    "autoRenewalStatus": "'
                                || lc_invoice_status
                                || '",
                    "invoiceStatus": "'
                                || lc_invoice_status
                                || '",
                    "serviceType": "'
                                || lr_contract_line_info.program
                                || '",
                    "contractStatus": "'
                                || px_subscription_array(indx).contract_status
                                || '", 
                    "action": "'
                                || lr_translation_info.target_value3 --future use
                                || '", 
                    "notificationDays":"'
                                || px_subscription_array(indx).next_retry_day
                                || '",
                    "nextRetryDate": "'
                                || TO_CHAR(lc_next_retry_date,'DD-MON-YYYY')  
                                || '",
                    "failureMessage": "'
                                || lc_failure_message
                                || '",  
                    "itemName": "'
                                || lr_contract_line_info.item_description
                                || '",
                    "contractNumber": "'
                                || px_subscription_array(indx).contract_number
                                || '",
                    "cancelDate": "'
                                || TO_CHAR(lc_cancel_date,'YYYY-MM-DD')
                                || '",
                    "reasonCode": "'
                                || lc_reason_code
                                || '",
                    "nextInvoiceDate": "'
                                ||  TO_CHAR(px_subscription_array(indx).next_billing_date,'DD-MON-YYYY HH24:MI:SS')
                                || '",
                    "contractStartDate": "'
                                || TO_CHAR(p_contract_info.contract_start_date,'DD-MON-YYYY HH24:MI:SS')
                                || '",
                    "contractEndDate": "'
                                || TO_CHAR(p_contract_info.contract_end_date,'DD-MON-YYYY HH24:MI:SS')
                                || '",
                    "servicePeriodStartDate": "'
                                || TO_CHAR(px_subscription_array(indx).service_period_start_date,'DD-MON-YYYY HH24:MI:SS')
                                || '",
                    "servicePeriodEndDate": "'
                                || TO_CHAR(px_subscription_array(indx).service_period_end_date,'DD-MON-YYYY HH24:MI:SS')
                                || '",
                    "totals": {
                            "subTotal": "'
                                || (ln_invoice_total_amount_info - px_subscription_array(indx).tax_amount) 
                                || '",
                            "tax": "'
                                || TO_CHAR(px_subscription_array(indx).tax_amount)
                                || '",
                            "delivery": "String",
                            "discount": "String",
                            "misc": "String",
                            "total": "'
                                || ln_invoice_total_amount_info
                                || '"
                    },
                    "tenders": {
                            "tenderLineNumber": "1",
                            "paymentType": "'
                                    || p_contract_info.payment_type
                                    || '",
                            "cardType": "'
                                    || p_contract_info.card_type
                                    || '",
                            "amount": "'
                                    || ln_invoice_total_amount_info
                                    || '",
                            "cardnumber": "'
                                    || lc_masked_credit_card_number
                                    || '",
                            "expirationDate": "'
                                    || lc_card_expiration_date
                                    || '",
                            "walletId": "'
                                    || lc_wallet_id
                                    ||'",
                            "billingAgreementId": "'
                                    || lc_billing_agreement_id
                                    || '"
                    }
                },
                "storeNumber": "' || p_contract_info.store_number || '"
            }
            }
            '
            INTO   lc_email_payload
            FROM   DUAL;

            lc_action := 'Validating Wallet location';

            IF p_program_setups('wallet_location') IS NOT NULL
            THEN

              lc_action := 'calling UTL_HTTP.set_wallet';

              UTL_HTTP.SET_WALLET(p_program_setups('wallet_location'), p_program_setups('wallet_password'));

            END IF;

            lc_action := 'Calling UTL_HTTP.set_response_error_check';

            UTL_HTTP.set_response_error_check(FALSE);

            lc_action := 'Calling UTL_HTTP.begin_request';

            l_request := UTL_HTTP.begin_request(p_program_setups('email_service_url'), 'POST', ' HTTP/1.1');

            lc_action := 'Calling UTL_HTTP.SET_HEADER: user-agent';

            UTL_HTTP.SET_HEADER(l_request, 'user-agent', 'mozilla/4.0');

            lc_action := 'Calling UTL_HTTP.SET_HEADER: content-type';

            UTL_HTTP.SET_HEADER(l_request, 'content-type', 'application/json');

            lc_action := 'Calling UTL_HTTP.SET_HEADER: Content-Length';

            UTL_HTTP.SET_HEADER(l_request, 'Content-Length', LENGTH(lc_email_payload));

            lc_action := 'Calling UTL_HTTP.SET_HEADER: Authorization';

            UTL_HTTP.SET_HEADER(l_request, 'Authorization', 'Basic ' || UTL_RAW.cast_to_varchar2(UTL_ENCODE.base64_encode(UTL_RAW.cast_to_raw(p_program_setups('email_service_user')
                                                                                                                                              || ':' ||
                                                                                                                                              p_program_setups('email_service_pwd')
                                                                                                                                              ))));
            lc_action := 'Calling UTL_HTTP.write_text';

            UTL_HTTP.write_text(l_request, lc_email_payload);

            lc_action := 'Calling UTL_HTTP.get_response';

            l_response := UTL_HTTP.get_response(l_request);

            COMMIT;

            logit(p_message => 'Response status_code' || l_response.status_code);

            /*************************
            * Get response into a CLOB
            *************************/

            lc_action := 'Getting response';

            BEGIN

              lclob_buffer := EMPTY_CLOB;
              LOOP

                UTL_HTTP.read_text(l_response, lc_buffer, LENGTH(lc_buffer));
                lclob_buffer := lclob_buffer || lc_buffer;

              END LOOP;

              logit(p_message => 'Response Clob: ' || lclob_buffer);

              UTL_HTTP.end_response(l_response);

            EXCEPTION
              WHEN UTL_HTTP.end_of_body
              THEN

                UTL_HTTP.end_response(l_response);

            END;

            /***********************
            * Store request/response
            ***********************/

            lc_action := 'Store request/response';

            lr_subscription_payload_info.payload_id              := xx_ar_subscription_payloads_s.NEXTVAL;
            lr_subscription_payload_info.response_data           := lclob_buffer;
            lr_subscription_payload_info.creation_date           := SYSDATE;
            lr_subscription_payload_info.created_by              := FND_GLOBAL.USER_ID;
            lr_subscription_payload_info.last_updated_by         := FND_GLOBAL.USER_ID;
            lr_subscription_payload_info.last_update_date        := SYSDATE;
            lr_subscription_payload_info.input_payload           := lc_email_payload;
            lr_subscription_payload_info.contract_number         := px_subscription_array(indx).contract_number;
            lr_subscription_payload_info.billing_sequence_number := px_subscription_array(indx).billing_sequence_number;
            lr_subscription_payload_info.contract_line_number    := NULL;
            lr_subscription_payload_info.source                  := lc_procedure_name;

            lc_action := 'Calling insert_subscription_payload_info';

            insert_subscript_payload_info(p_subscription_payload_info => lr_subscription_payload_info);

            IF (l_response.status_code = 200)
            THEN

              lc_email_sent_counter := lc_email_sent_counter + 1;
 
              px_subscription_array(indx).email_sent_flag  := 'Y';
              px_subscription_array(indx).email_sent_date  := SYSDATE;
              px_subscription_array(indx).last_update_date := SYSDATE;
              px_subscription_array(indx).last_updated_by  := FND_GLOBAL.USER_ID;

            ELSE

              lc_action := NULL;

              lc_error  := 'Email sent failure - response code: ' || l_response.status_code;

              RAISE le_processing;

            END IF;

          ELSE

              px_subscription_array(indx).email_sent_flag  := 'Y';
              px_subscription_array(indx).email_sent_date  := SYSDATE;
              px_subscription_array(indx).last_update_date := SYSDATE;
              px_subscription_array(indx).last_updated_by  := FND_GLOBAL.USER_ID;
              
              IF px_subscription_array(indx).contract_status IS NULL
              THEN
    
                px_subscription_array(indx).contract_status  := lc_contract_status;  
                px_subscription_array(indx).next_retry_day   := lc_next_retry_day;   

               END IF;

          END IF;--ln_loop_counter end if

        END IF;--px_subscription_array(indx).billing_sequence_number >= lr_contract_line_info.initial_billing_sequence

        lc_action := 'Calling update_subscription_info';

        update_subscription_info(px_subscription_info => px_subscription_array(indx));

      EXCEPTION
        WHEN le_processing
        THEN

          lr_subscription_error_info                         := NULL;
          lr_subscription_error_info.contract_id             := px_subscription_array(indx).contract_id;
          lr_subscription_error_info.contract_number         := px_subscription_array(indx).contract_number;
          lr_subscription_error_info.contract_line_number    := NULL;
          lr_subscription_error_info.billing_sequence_number := px_subscription_array(indx).billing_sequence_number;
          lr_subscription_error_info.error_module            := lc_procedure_name;
          lr_subscription_error_info.error_message           := SUBSTR('Action: ' || lc_action || ' Error: ' || lc_error, 1, gc_max_err_size);
          lr_subscription_error_info.creation_date           := SYSDATE;

          lc_action := 'Calling insert_subscription_error_info';

          insert_subscription_error_info(p_subscription_error_info => lr_subscription_error_info);

          lc_email_sent_flag := 'E';
          lc_error := SUBSTR(lr_subscription_error_info.error_message, 1, gc_max_sub_err_size);

          RAISE le_processing;

        WHEN OTHERS
        THEN

          lr_subscription_error_info                         := NULL;
          lr_subscription_error_info.contract_id             := px_subscription_array(indx).contract_id;
          lr_subscription_error_info.contract_number         := px_subscription_array(indx).contract_number;
          lr_subscription_error_info.contract_line_number    := NULL;
          lr_subscription_error_info.billing_sequence_number := px_subscription_array(indx).billing_sequence_number;
          lr_subscription_error_info.error_module            := lc_procedure_name;
          lr_subscription_error_info.error_message           := SUBSTR('Action: ' || lc_action || ' Error: ' || SQLCODE || ' ' || SQLERRM, 1, gc_max_err_size);
          lr_subscription_error_info.creation_date           := SYSDATE;

          lc_action := 'Calling insert_subscription_error_info';

          insert_subscription_error_info(p_subscription_error_info => lr_subscription_error_info);

          lc_email_sent_flag := 'E';
          lc_error := SUBSTR(lr_subscription_error_info.error_message, 1, gc_max_sub_err_size);

          RAISE le_processing;

      END;

    END LOOP;

    logit(p_message => 'EMAIL service executed successfully ' || lc_email_sent_counter || ' time.');

    exiting_sub(p_procedure_name => lc_procedure_name);

  EXCEPTION
    WHEN le_skip
    THEN

      logit(p_message => 'Skipping: ' || lc_error);

    WHEN le_processing
    THEN

      FOR indx IN 1 .. px_subscription_array.COUNT
      LOOP

        IF px_subscription_array(indx).contract_status IS NULL
        THEN
          px_subscription_array(indx).contract_status    :=  lc_contract_status;
          px_subscription_array(indx).next_retry_day     :=  lc_next_retry_day;
        END IF;

        px_subscription_array(indx).email_sent_flag    := lc_email_sent_flag;
        px_subscription_array(indx).subscription_error := lc_error;

        lc_action := 'Calling update_subscription_info to update with error info';

        update_subscription_info(px_subscription_info => px_subscription_array(indx));

      END LOOP;

      exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => TRUE);

      RAISE_APPLICATION_ERROR(-20101, lc_error);

    WHEN OTHERS
    THEN

      FOR indx IN 1 .. px_subscription_array.COUNT
      LOOP

        IF px_subscription_array(indx).contract_status IS NULL
        THEN
          px_subscription_array(indx).contract_status    :=  lc_contract_status;
          px_subscription_array(indx).next_retry_day     :=  lc_next_retry_day;
        END IF;

        px_subscription_array(indx).email_sent_flag    := 'E';
        px_subscription_array(indx).subscription_error := SUBSTR('Action: ' || lc_action || 'SQLCODE: ' || SQLCODE || ' SQLERRM: ' || SQLERRM, 1, gc_max_sub_err_size);

        lc_action := 'Calling update_subscription_info to update with error info';

        update_subscription_info(px_subscription_info => px_subscription_array(indx));

      END LOOP;

      exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => TRUE);
      RAISE_APPLICATION_ERROR(-20101, 'PROCEDURE: ' || lc_procedure_name || ' Action: ' || lc_action || ' SQLCODE: ' || SQLCODE || ' SQLERRM: ' || SQLERRM);

  END send_billing_email;
  

  /*****************************************
  * Helper procedure to send billing history
  *****************************************/

  PROCEDURE send_billing_history(p_program_setups      IN            gt_translation_values,
                                 p_contract_info       IN            xx_ar_contracts%ROWTYPE,
                                 px_subscription_array IN OUT NOCOPY subscription_table)
  IS

    lc_procedure_name    CONSTANT  VARCHAR2(61) := gc_package_name || '.' || 'send_billing_history';

    lc_masked_credit_card_number  xx_ar_subscriptions.settlement_cc_mask%TYPE;

    lt_parameters                  gt_input_parameters;

    lc_action                      VARCHAR2(1000);

    lc_error                       VARCHAR2(1000);

    ln_loop_counter                NUMBER := 0;

    lr_contract_line_info          xx_ar_contract_lines%ROWTYPE;

    lr_invoice_header_info         ra_customer_trx_all%ROWTYPE;

    ln_invoice_total_amount_info   ra_customer_trx_lines_all.extended_amount%TYPE;

    lr_bill_to_cust_location_info  hz_locations%ROWTYPE;

    lc_billing_agreement_id        xx_ar_contracts.payment_identifier%TYPE;

    lc_wallet_id                   xx_ar_contracts.payment_identifier%TYPE;

    lc_card_expiration_date        VARCHAR2(4);

    lc_history_sent_flag           VARCHAR2(2) := 'N';

    lr_subscription_payload_info   xx_ar_subscription_payloads%ROWTYPE;

    lr_subscription_error_info     xx_ar_subscriptions_error%ROWTYPE;

    lc_item_unit_total             xx_ar_subscriptions.total_contract_amount%TYPE;

    le_skip                        EXCEPTION;

    le_processing                  EXCEPTION;

    lc_history_payload             VARCHAR2(32000) := NULL;

    lb_history_hrd_processed       BOOLEAN := FALSE;

    lc_history_payload_lines       VARCHAR2(10000) := NULL;

    lc_history_payload_tender      VARCHAR2(10000) := NULL;

    lr_order_header_info           oe_order_headers_all%ROWTYPE;

    lr_bill_to_cust_acct_site_info hz_cust_acct_sites_all%ROWTYPE;

    l_request                      UTL_HTTP.req;
    
    l_response                     UTL_HTTP.resp;

    lc_buff                        VARCHAR2(10000);
                                   
    lc_clob_buff                   CLOB;

    lc_parentheses                 VARCHAR2(100)   := NULL;

    lc_contract_line               VARCHAR2(10000) := NULL;

    lc_invoice_status              VARCHAR2(25)    := NULL;
    
    lr_pos_ordt_info               xx_ar_order_receipt_dtl%ROWTYPE;
    
    lr_pos_info                    xx_ar_pos_inv_order_ref%ROWTYPE;
    
    lr_customer_info               hz_cust_accounts%ROWTYPE;
    
    lc_failure_message             VARCHAR2(256)   := NULL;
    
    lc_auth_time                   xx_ar_subscriptions.auth_datetime%TYPE;
    
    lc_next_retry_date             DATE;

  BEGIN

    entering_sub(p_procedure_name  => lc_procedure_name,
                 p_parameters      => lt_parameters);

    /*************************************************************************************
    * Validate we have all the information in subscriptions needed to send billing history
    *************************************************************************************/

    lc_action := 'Looping thru subscription array for prevalidation';

    FOR indx IN 1 .. px_subscription_array.COUNT
    LOOP

      /***************************
      * Validate for authorization
      ***************************/
      IF p_contract_info.payment_type = 'AB'
      THEN
        IF px_subscription_array(indx).receipt_created_flag NOT IN ('Y', 'P')
        THEN
          lc_error := 'Receipt creation is not completed';
          RAISE le_skip;
        END IF;
      ELSE 
        IF px_subscription_array(indx).auth_completed_flag NOT IN ('Y', 'E')
        THEN
          lc_error := 'Authorization is not completed';
          RAISE le_skip;
        END IF;
      END IF;

      /**************************************
      * Validate we are ready to send history
      **************************************/

      IF px_subscription_array(indx).history_sent_flag NOT IN ('N', 'E')
      THEN

        lc_error := 'History Sent flag: ' || px_subscription_array(indx).history_sent_flag;
        RAISE le_skip;

      END IF;
      
      /******************************
      * Get contract line information
      ******************************/

      lc_action := 'Calling get_contract_line_info send_billing_history';

      get_contract_line_info(p_contract_id          => px_subscription_array(indx).contract_id,
                             p_contract_line_number => px_subscription_array(indx).contract_line_number,
                             x_contract_line_info   => lr_contract_line_info);
                             
      IF lr_contract_line_info.item_name = p_program_setups('termination_sku')
      THEN 
        lc_error := 'Termination SKU : ' || lr_contract_line_info.item_name;
        RAISE le_skip;
      END IF;
      
      IF TRUNC(px_subscription_array(indx).history_sent_date) = TRUNC(SYSDATE)
      THEN 
        lc_error := 'History Sent date : ' || px_subscription_array(indx).history_sent_date;
        RAISE le_skip;
      END IF;

    END LOOP;

    lc_action := 'Setting transaction savepoint';

    SAVEPOINT sp_transaction;

    /*******************************************************************
    * Loop thru all the information in subscriptions for sending history
    *******************************************************************/

    lc_action := 'Looping thru subscription array for history service - header information';

    FOR indx IN 1 .. px_subscription_array.COUNT
    LOOP

      BEGIN
      
        /************************************
        * Get contract line level information
        ************************************/
        
        lc_action := 'Calling get_contract_line_info send_billing_history2';
        
        get_contract_line_info(p_contract_id          => px_subscription_array(indx).contract_id,
                               p_contract_line_number => px_subscription_array(indx).contract_line_number,
                               x_contract_line_info   => lr_contract_line_info);

        IF  px_subscription_array(indx).billing_sequence_number < lr_contract_line_info.initial_billing_sequence
        AND lr_contract_line_info.program = 'SS'
        THEN

          px_subscription_array(indx).history_sent_flag := 'Y';

          lc_action := 'Calling update_subscription_info';

          update_subscription_info(px_subscription_info => px_subscription_array(indx));
          
        ELSIF px_subscription_array(indx).billing_sequence_number >= lr_contract_line_info.initial_billing_sequence
        THEN

          IF lb_history_hrd_processed != TRUE
          THEN

            /************************
            * Get invoice information
            ************************/

            lc_action := 'Calling get_invoice_header_info';

            get_invoice_header_info(p_invoice_number      => px_subscription_array(indx).invoice_number,
                                    x_invoice_header_info => lr_invoice_header_info);

            /******************************
            * Get invoice total information
            ******************************/

            lc_action := 'Calling get_invoice_total_amount_info';

            get_invoice_total_amount_info(p_customer_trx_id           => lr_invoice_header_info.customer_trx_id,
                                          x_invoice_total_amount_info => ln_invoice_total_amount_info);

            /******************************
            * Get initial order header info
            ******************************/

            lc_action := 'Calling get_order_header_info';

            IF p_contract_info.external_source = 'POS'
            THEN
              get_pos_ordt_info(p_order_number => p_contract_info.initial_order_number,
                    x_ordt_info    => lr_pos_ordt_info);
                    
              get_pos_info(p_header_id        => lr_pos_ordt_info.header_id,
                           p_orig_sys_doc_ref => p_contract_info.initial_order_number,
                           x_pos_info         => lr_pos_info);
                           
              get_order_header_info(--p_order_number      => lr_pos_info.sales_order,            --Commented for NAIT-126620.
                                    p_order_number      => p_contract_info.initial_order_number, --Added for NAIT-126620
                                    x_order_header_info => lr_order_header_info);
            ELSE
              get_order_header_info(p_order_number      => p_contract_info.initial_order_number,
                                    x_order_header_info => lr_order_header_info);
            END IF;

            /*************************************************
            * Get initial order BILL_TO cust account site info
            *************************************************/

            lc_action := 'Calling get_cust_account_site_info for BILL_TO';

            IF p_contract_info.external_source = 'POS'
            THEN
              get_customer_pos_info(p_aops           => p_contract_info.bill_to_osr,
                                    x_customer_info  => lr_customer_info);
                                  
              get_cust_site_pos_info(p_customer_id     => lr_customer_info.cust_account_id,
                                     x_cust_site_info  => lr_bill_to_cust_acct_site_info);
            ELSE
              get_cust_account_site_info(p_site_use_id            => lr_order_header_info.invoice_to_org_id,
                                         p_site_use_code          => 'BILL_TO',
                                         x_cust_account_site_info => lr_bill_to_cust_acct_site_info);
            END IF;

            /***********************************
            * Get initial order BILL_TO location
            ***********************************/

            lc_action := 'Calling get_cust_location_info for BILL_TO';

            get_cust_location_info(p_cust_acct_site_id  => lr_bill_to_cust_acct_site_info.cust_acct_site_id,
                                   x_cust_location_info => lr_bill_to_cust_location_info);

            /*********************
            * Masking card details
            *********************/

            lc_action := 'Masking credit card';

            lc_masked_credit_card_number := LPAD(SUBSTR(px_subscription_array(indx).settlement_cc_mask, -4), 16, 'x');

            /**********************************************************************
            * If paypal, pass billing application id, if masterpass, pass wallet id
            **********************************************************************/

            IF p_contract_info.card_type = 'PAYPAL'
            THEN

              lc_billing_agreement_id := p_contract_info.payment_identifier;

            ELSE

              lc_wallet_id := p_contract_info.payment_identifier;

            END IF;

            /***********************
            * Format expiration date
            ***********************/

            IF p_contract_info.card_expiration_date IS NOT NULL
            THEN

              lc_action := 'Formating card_expiration_date';

              lc_card_expiration_date := TO_CHAR(p_contract_info.card_expiration_date, 'YYMM'); 

            END IF;

            /************************************************
            * Assigning invoice status based on authorization
            ************************************************/
            lc_action := 'Assiging invoice status based on authorizaiton';

            IF p_contract_info.payment_type != 'AB'
            THEN
              IF px_subscription_array(indx).auth_completed_flag = 'Y'
              THEN
              
                lc_invoice_status  := 'OK';
                
                lc_failure_message := NULL;
                
                lc_auth_time       := px_subscription_array(indx).auth_datetime;
                
                lc_next_retry_date := NULL;
              
              ELSE
              
                lc_invoice_status  := 'FAIL';
                
                lc_failure_message := px_subscription_array(indx).auth_message;
                
                lc_auth_time       := px_subscription_array(indx).auth_datetime;
                
                lc_next_retry_date := NVL(px_subscription_array(indx).initial_auth_attempt_date,SYSDATE) + px_subscription_array(indx).next_retry_day;
              
              END IF;
            ELSE
            
              lc_invoice_status  := 'OK';
              
              lc_failure_message := NULL;
              
              lc_auth_time       := NULL;

            END IF;

            /**********************
            * Build history payload
            **********************/

            lc_action := 'Building history payload - header information';

            SELECT    '{
                "billingHistoryRequest": {
                    "transactionHeader": {
                         "consumerName": "EBS",
                         "consumerTransactionId":"'
                                || p_contract_info.contract_number
                                || '-'
                                || p_contract_info.initial_order_number
                                || '-'
                                || px_subscription_array(indx).billing_sequence_number
                                || '-'
                                || TO_CHAR(SYSDATE,
                                           'DDMONYYYYHH24MISS')
                                || '",
                         "consumerTransactionDateTime":"'
                                || TO_CHAR(SYSDATE,
                                           'YYYY-MM-DD')
                                || 'T'
                                || TO_CHAR(SYSDATE,
                                           'HH24:MI:SS')
                                || '"
                    },
                    "customer": {
                         "paymentDetails": {
                            "paymentType": "'
                                || p_contract_info.payment_type
                                || '"
                        }
                    },
                    "invoice": {
                         "invoiceNumber": "'
                                ||  px_subscription_array(indx).invoice_number
                                || '",
                         "orderNumber":  "'
                                ||  px_subscription_array(indx).initial_order_number--SUBSTR(px_subscription_array(indx).initial_order_number,1,9)||SUBSTR(px_subscription_array(indx).initial_order_number,11,13)
                                || '",
                         "serviceContractNumber": "'
                                ||  px_subscription_array(indx).contract_number
                                || '",
                         "contractModifier": "'
                                ||  p_contract_info.contract_number_modifier
                                || '",
                         "billingSequenceNumber": "'
                                ||  px_subscription_array(indx).billing_sequence_number
                                || '",
                         "contractId": "'
                                ||  px_subscription_array(indx).contract_id
                                || '",
                         "billingDate": "'
                                || TO_CHAR(px_subscription_array(indx).billing_date,
                                          'DD-MON-YYYY')
                                || '",
                         "invoiceDate": "'
                                || TO_CHAR(lr_invoice_header_info.trx_date,
                                          'DD-MON-YYYY')
                                || '",
                         "invoiceTime": "'
                                || TO_CHAR(lr_invoice_header_info.trx_date,
                                           'HH24:MI:SS')
                                || '",
                         "invoiceStatus": "'
                                || lc_invoice_status
                                || '",
                         "servicePeriodStartDate": "'
                                || TO_CHAR(px_subscription_array(indx).service_period_start_date,
                                          'DD-MON-YYYY HH24:MI:SS')
                                || '",
                         "servicePeriodEndDate": "'
                                || TO_CHAR(px_subscription_array(indx).service_period_end_date,
                                           'DD-MON-YYYY HH24:MI:SS')
                                || '",
                         "nextBillingDate": "'
                                || TO_CHAR(px_subscription_array(indx).next_billing_date,
                                          'DD-MON-YYYY')
                                || '",
                          "totals": {
                              "subTotal": "'
                                    || (ln_invoice_total_amount_info - px_subscription_array(indx).tax_amount) 
                                    || '",
                              "tax": "'
                                    || TO_CHAR(px_subscription_array(indx).tax_amount)
                                    || '",
                              "delivery": "String",
                              "discount": "String",
                              "misc": "String",
                              "total": "'
                                    || ln_invoice_total_amount_info
                                    || '"
                          },
                         "invoiceLines": {
                             "invoiceLine":
                                  ['
            INTO  lc_history_payload
            FROM  DUAL;

            lc_action := 'Building history payload - tender information';

            SELECT                ']},
                         "tenders": {
                             "cardType": "'
                                  || p_contract_info.card_type
                                  || '",
                             "amount": "'
                                  || ln_invoice_total_amount_info
                                  || '",
                             "cardnumber": "'
                                  || lc_masked_credit_card_number
                                  || '",
                             "expirationDate": "'
                                  || lc_card_expiration_date
                                  || '"
                         }
                    },
                    "contract": {
                         "contractLines": [
                 '
            INTO   lc_history_payload_tender
            FROM   DUAL;

            SELECT '         
                         ]
                    }
                }
                }'
           INTO     lc_parentheses
           FROM     dual;

            ln_loop_counter := ln_loop_counter + 1;

            lb_history_hrd_processed := TRUE;

          END IF;

          /******************************************************************
          * Calculating total line amount (contract_line_amount + tax_amount)
          ******************************************************************/

          lc_action := 'Calculating total line amount';

          lc_item_unit_total := px_subscription_array(indx).total_contract_amount * lr_contract_line_info.quantity
                                       + NVL(px_subscription_array(indx).tax_amount, 0);

          /***********************************
          * Build history payload - line level
          ***********************************/

          lc_action := 'Building history payload - line information';

          SELECT                 '{
                                    "orderLineNumber": "'
                                         || lr_contract_line_info.initial_order_line
                                         || '",
                                    "contractLineNumber": "'
                                         || lr_contract_line_info.contract_line_number
                                         || '",
                                    "itemNumber": "'
                                         || lr_contract_line_info.item_name
                                         || '",
                                    "contractStartDate": "'
                                         || TO_CHAR(lr_contract_line_info.contract_line_start_date,'YYYY-MM-DD')
                                         || '",
                                    "contractEndDate": "'
                                         || TO_CHAR(lr_contract_line_info.contract_line_end_date,'YYYY-MM-DD')
                                         || '",
                                    "billingFrequency": "'
                                         || lr_contract_line_info.contract_line_billing_freq
                                         || '",
                                    "unitPrice": "'
                                         || px_subscription_array(indx).contract_line_amount
                                         || '",
                                    "tax": "'
                                         || NVL(px_subscription_array(indx).tax_amount, 0)
                                         || '",
                                    "unitTotal": "'
                                         || lc_item_unit_total
                                         || '",
                                    "failureMessage": "'
                                         || lc_failure_message
                                         || '",
                                    "initialAuthDate": "'
                                         || TO_CHAR(px_subscription_array(indx).initial_auth_attempt_date,'YYYY-MM-DD')
                                         || '",
                                    "lastAuthDate": "'
                                         || TO_CHAR(px_subscription_array(indx).last_auth_attempt_date,'YYYY-MM-DD')
                                         || '",
                                    "nextRetryDate": "'
                                         || TO_CHAR(lc_next_retry_date,'DD-MON-YYYY')
                                         || '"
                                  }'
          INTO   lc_history_payload_lines
          FROM   DUAL;
  
          SELECT '           {
                                 "startDate": "'
                                      || TO_CHAR(lr_contract_line_info.contract_line_start_date,'DD-MON-YYYY HH24:MI:SS')
                                      || '",
                                 "endDate" :"'
                                      || TO_CHAR(lr_contract_line_info.contract_line_end_date,'DD-MON-YYYY HH24:MI:SS')
                                      || '",
                                 "serviceType": "'
                                      || lr_contract_line_info.program
                                      || '",
                                 "billingFrequency": "'
                                      || lr_contract_line_info.contract_line_billing_freq
                                      || '",
                                 "vendorNumber": "'
                                      || lr_contract_line_info.vendor_number
                                      || '",
                                 "lineNumber": "'
                                      || lr_contract_line_info.contract_line_number
                                      || '",
                                 "contractLineAmount": "'
                                      || px_subscription_array(indx).contract_line_amount
                                      || '",
                                 "totalContractLineAmount": "'
                                      || lr_contract_line_info.contract_line_amount
                                      || '"
                             }'
          INTO   lc_contract_line
          FROM   DUAL;

          /************************************************
          * Need a comma between payload line level records
          ************************************************/

          IF ln_loop_counter = 1
          THEN

            lc_history_payload := lc_history_payload
                                  || ''
                                  || lc_history_payload_lines;

            lc_history_payload_tender := lc_history_payload_tender
                                         ||''
                                         ||lc_contract_line;

            ln_loop_counter := ln_loop_counter + 1;

          ELSE

            lc_history_payload := lc_history_payload
                                  || ','
                                  || lc_history_payload_lines;

            lc_history_payload_tender := lc_history_payload_tender
                                         ||','
                                         ||lc_contract_line;

            ln_loop_counter := ln_loop_counter + 1;

          END IF;

          /**********************************************************************************
          * This is the last px_subscription_array record therefore appending tender payload,
          * sending payload, recording response. 
          *********************************************************************************/

          IF  (ln_loop_counter - 1) = px_subscription_array.COUNT
          THEN

            lc_action := 'Concatenating tender information to history payload';

            lc_history_payload := lc_history_payload
                                  || ''
                                  || lc_history_payload_tender
                                  ||''
                                  || lc_parentheses;
                                  
            lc_action := 'Validating Wallet location';
    
            IF p_program_setups('wallet_location') IS NOT NULL
            THEN
                
                lc_action := 'calling UTL_HTTP.set_wallet';
                
                UTL_HTTP.set_wallet(p_program_setups('wallet_location'),
                                    p_program_setups('wallet_password'));
            END IF;
                
            lc_action := 'Calling UTL_HTTP.set_response_error_check';
              
            UTL_HTTP.set_response_error_check(FALSE);
            
            lc_action := 'Calling UTL_HTTP.begin_request';
            
            l_request := UTL_HTTP.begin_request(p_program_setups('history_service_url'),
                                               'POST',
                                               'HTTP/1.2');
            
            lc_action := 'UTL_HTTP.set_header : user-agent';
            
            UTL_HTTP.set_header(l_request,
                                'user-agent',
                                'mozilla/5.0');
                                
            lc_action := 'UTL_HTTP.set_header : content-type';
            
            UTL_HTTP.set_header(l_request,
                                'content-type',
                                'application/json');
                                
            lc_action := 'UTL_HTTP.set_header : Content-Length';
            
            UTL_HTTP.set_header(l_request,
                                'Content-Length',
                                LENGTH(lc_history_payload) );
                                
            lc_action := 'UTL_HTTP.set_header : Authorization';
            
            UTL_HTTP.set_header
                (l_request,
                 'Authorization',
                 'Basic '
                 || UTL_RAW.cast_to_varchar2
                                           (UTL_ENCODE.base64_encode(UTL_RAW.cast_to_raw(   p_program_setups('history_service_user')
                                                                                         || ':'
                                                                                         || p_program_setups('history_service_pwd')) ) ) );
            
            lc_action := 'UTL_HTTP.write_text';
            
            UTL_HTTP.write_text(l_request,
                                lc_history_payload);
                                
            lc_action := 'Calling UTL_HTTP.get_response';
        
            l_response := UTL_HTTP.get_response(l_request);
            
            COMMIT;

            logit(p_message =>'HTTP response status code: '|| l_response.status_code);            
            
            /*************************
            * Get response into a CLOB
            *************************/

            lc_action := 'Getting response';
            
            BEGIN
              lc_clob_buff := EMPTY_CLOB;

              LOOP
                
                UTL_HTTP.read_text(l_response,
                                   lc_buff,
                                   LENGTH(lc_buff) );
                lc_clob_buff :=    lc_clob_buff
                                || lc_buff;
                logit(p_message => 'Response : '|| lc_clob_buff);
              
              END LOOP;

              UTL_HTTP.end_response(l_response);
            
            EXCEPTION
              WHEN UTL_HTTP.end_of_body
              THEN
                UTL_HTTP.end_response(l_response);
              WHEN OTHERS
              THEN
                logit(p_message => 'Error in reading response - SQLERRM : '||SQLERRM);
                UTL_HTTP.end_response(l_response);
            END;

            /***********************
            * Store request/response
            ***********************/

            lc_action := 'Store request/response';

            lr_subscription_payload_info.payload_id              := xx_ar_subscription_payloads_s.NEXTVAL;
            lr_subscription_payload_info.response_data           := lc_clob_buff;
            lr_subscription_payload_info.creation_date           := SYSDATE;
            lr_subscription_payload_info.created_by              := FND_GLOBAL.USER_ID;
            lr_subscription_payload_info.last_updated_by         := FND_GLOBAL.USER_ID;
            lr_subscription_payload_info.last_update_date        := SYSDATE;
            lr_subscription_payload_info.input_payload           := lc_history_payload;
            lr_subscription_payload_info.contract_number         := px_subscription_array(indx).contract_number;
            lr_subscription_payload_info.billing_sequence_number := px_subscription_array(indx).billing_sequence_number;
            lr_subscription_payload_info.contract_line_number    := NULL;
            lr_subscription_payload_info.source                  := lc_procedure_name;

            lc_action := 'Calling insert_subscription_payload_info';

            insert_subscript_payload_info(p_subscription_payload_info => lr_subscription_payload_info);

            IF (l_response.status_code IN (200, 201))
            THEN

              FOR indx IN 1 .. px_subscription_array.COUNT
              LOOP

                px_subscription_array(indx).history_sent_flag := 'Y';
                px_subscription_array(indx).history_sent_date := SYSDATE;
                px_subscription_array(indx).last_update_date  := SYSDATE;
                px_subscription_array(indx).last_updated_by   := FND_GLOBAL.USER_ID;
                
                --updating auth_completed_flag to T if contractStatus is TERMINATE
                IF  px_subscription_array(indx).contract_status = gc_contract_status
                THEN
                
                  px_subscription_array(indx).auth_completed_flag := 'T';
                
                END IF;

                lc_action := 'Calling update_subscription_info';

                update_subscription_info(px_subscription_info => px_subscription_array(indx));

              END LOOP;

            ELSE

              lc_action := NULL;

              lc_error  := 'History sent failure - response code: ' || l_response.status_code;

              RAISE le_processing;

            END IF;

          END IF;--ln_loop_counter = px_subscription_array.COUNT

        END IF;--px_subscription_array(indx).billing_sequence_number != 1 end if

      EXCEPTION
        WHEN le_processing
        THEN

          lr_subscription_error_info                         := NULL;
          lr_subscription_error_info.contract_id             := px_subscription_array(indx).contract_id;
          lr_subscription_error_info.contract_number         := px_subscription_array(indx).contract_number;
          lr_subscription_error_info.contract_line_number    := NULL;
          lr_subscription_error_info.billing_sequence_number := px_subscription_array(indx).billing_sequence_number;
          lr_subscription_error_info.error_module            := lc_procedure_name;
          lr_subscription_error_info.error_message           := SUBSTR('Action: ' || lc_action || ' Error: ' || lc_error, 1, gc_max_err_size);
          lr_subscription_error_info.creation_date           := SYSDATE;

          lc_action := 'Calling insert_subscription_error_info';

          insert_subscription_error_info(p_subscription_error_info => lr_subscription_error_info);

          lc_history_sent_flag := 'E';
          lc_error := SUBSTR(lr_subscription_error_info.error_message, 1, gc_max_sub_err_size);

          RAISE le_processing;

        WHEN OTHERS
        THEN

          lr_subscription_error_info                         := NULL;
          lr_subscription_error_info.contract_id             := px_subscription_array(indx).contract_id;
          lr_subscription_error_info.contract_number         := px_subscription_array(indx).contract_number;
          lr_subscription_error_info.contract_line_number    := NULL;
          lr_subscription_error_info.billing_sequence_number := px_subscription_array(indx).billing_sequence_number;
          lr_subscription_error_info.error_module            := lc_procedure_name;
          lr_subscription_error_info.error_message           := SUBSTR('Action: ' || lc_action || ' Error: ' || SQLCODE || ' ' || SQLERRM, 1, gc_max_err_size);
          lr_subscription_error_info.creation_date           := SYSDATE;

          lc_action := 'Calling insert_subscription_error_info';

          insert_subscription_error_info(p_subscription_error_info => lr_subscription_error_info);

          lc_history_sent_flag := 'E';
          lc_error := SUBSTR(lr_subscription_error_info.error_message, 1, gc_max_sub_err_size);

          RAISE le_processing;
      END;

    END LOOP;
    
    exiting_sub(p_procedure_name => lc_procedure_name);

  EXCEPTION

    WHEN le_skip
    THEN

      logit(p_message => 'Skipping: ' || lc_error);

    WHEN le_processing
    THEN

      FOR indx IN 1 .. px_subscription_array.COUNT
      LOOP

        px_subscription_array(indx).history_sent_flag := lc_history_sent_flag;
        px_subscription_array(indx).subscription_error := lc_error;

        lc_action := 'Calling update_subscription_info to update with error info';

        update_subscription_info(px_subscription_info => px_subscription_array(indx));

      END LOOP;

      exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => TRUE);
      RAISE_APPLICATION_ERROR(-20101, lc_error);

    WHEN OTHERS
    THEN

      FOR indx IN 1 .. px_subscription_array.COUNT
      LOOP

        px_subscription_array(indx).history_sent_flag := 'E';
        px_subscription_array(indx).subscription_error := SUBSTR('Action: ' || lc_action || 'SQLCODE: ' || SQLCODE || ' SQLERRM: ' || SQLERRM, 1, gc_max_sub_err_size);

        lc_action := 'Calling update_subscription_info to update with error info';

        update_subscription_info(px_subscription_info => px_subscription_array(indx));

      END LOOP;

      exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => TRUE);
      RAISE_APPLICATION_ERROR(-20101, 'PROCEDURE: ' || lc_procedure_name || ' Action: ' || lc_action || ' SQLCODE: ' || SQLCODE || ' SQLERRM: ' || SQLERRM);

  END send_billing_history;

  /************************************
  * Helper procedure to process receipt
  ************************************/

  PROCEDURE process_receipt(p_program_setups      IN            gt_translation_values,
                            p_contract_info       IN            xx_ar_contracts%ROWTYPE,
                            px_subscription_array IN OUT NOCOPY subscription_table)
  IS

    lc_procedure_name    CONSTANT  VARCHAR2(61) := gc_package_name || '.' || 'process_receipt';

    lt_parameters                  gt_input_parameters;

    lc_action                      VARCHAR2(1000);

    lc_error                       VARCHAR2(2000);

    ln_loop_counter                NUMBER := 0;

    lr_order_header_info           oe_order_headers_all%ROWTYPE;
    
    lr_contract_line_info          xx_ar_contract_lines%ROWTYPE;

    lr_invoice_header_info         ra_customer_trx_all%ROWTYPE;

    ln_invoice_total_amount_info   ra_customer_trx_lines_all.extended_amount%TYPE;

    lr_customer_info               hz_cust_accounts%ROWTYPE;

    lr_attrib                      ar_receipt_api_pub.attribute_rec_type;

    ln_cash_receipt_id             ar_cash_receipts_all.cash_receipt_id%TYPE;

    lr_receipt_info                ar_cash_receipts_all%ROWTYPE;

    lc_receipt_created_flag        xx_ar_subscriptions.receipt_created_flag%TYPE;

    lc_receipt_number              xx_ar_subscriptions.receipt_number%TYPE;

    lr_rec_application_info        ar_receivable_applications_all%ROWTYPE;

    lr_subscription_error_info     xx_ar_subscriptions_error%ROWTYPE;

    lc_return_status               VARCHAR2(1)     := NULL;

    lc_msg_data                    VARCHAR2(2000)  := NULL;

    ln_msg_count                   NUMBER          := 0;

    ln_receipt_count               NUMBER          := 0;

    le_skip                        EXCEPTION;

    le_processing                  EXCEPTION;
    
    lr_pos_ordt_info               xx_ar_order_receipt_dtl%ROWTYPE;
    
    lr_pos_info                    xx_ar_pos_inv_order_ref%ROWTYPE;

  BEGIN

    entering_sub(p_procedure_name  => lc_procedure_name,
                 p_parameters      => lt_parameters);


    /*********************************************************************************
    * Validate we have all the information in subscriptions needed to process receipt
    *********************************************************************************/

    lc_action := 'Looping thru subscription array for prevalidation';

    FOR indx IN 1 .. px_subscription_array.COUNT
    LOOP

      /***********************
      * Validate auth was done
      ***********************/

      IF px_subscription_array(indx).auth_completed_flag != 'Y'
      THEN

        lc_error := 'Auth not completed';
        RAISE le_skip;

      END IF;

      /****************************************
      * Validate we are ready to create receipt
      ****************************************/

      IF px_subscription_array(indx).receipt_created_flag NOT IN ('N', 'E')
      THEN

        lc_error := 'Receipt flag: ' || px_subscription_array(indx).receipt_created_flag;
        RAISE le_skip;

      END IF;

    END LOOP;

    lc_action := 'Setting transaction savepoint';

    SAVEPOINT sp_transaction;

    /***********************************************************************
    * Loop thru all the information in subscriptions for interfacing invoice
    ***********************************************************************/

    lc_action := 'Looping thru subscription array for receipt processing';

    FOR indx IN 1 .. px_subscription_array.COUNT
    LOOP
      BEGIN
      
        /******************************
        * Get contract line information
        ******************************/

        lc_action := 'Calling get_contract_line_info process_receipt';

        get_contract_line_info(p_contract_id          => px_subscription_array(indx).contract_id,
                               p_contract_line_number => px_subscription_array(indx).contract_line_number,
                               x_contract_line_info   => lr_contract_line_info);

        IF  px_subscription_array(indx).billing_sequence_number < lr_contract_line_info.initial_billing_sequence
        --AND lr_contract_line_info.program = 'SS'
        THEN

          /************************
          * Get invoice information
          ************************/
          
          /*IF (lr_invoice_header_info.customer_trx_id IS NULL)
          THEN
          
            lc_action := 'Calling get_invoice_header_info';
          
            IF p_contract_info.external_source = 'POS'
            THEN
              get_pos_ordt_info(p_order_number => p_contract_info.initial_order_number,
                    x_ordt_info    => lr_pos_ordt_info);
                    
              get_pos_info(p_header_id        => lr_pos_ordt_info.header_id,
                           p_orig_sys_doc_ref => p_contract_info.initial_order_number,
                           x_pos_info         => lr_pos_info);
                           
              get_invoice_header_info(p_invoice_number      => lr_pos_info.summary_trx_number,
                                      x_invoice_header_info => lr_invoice_header_info);
            ELSE
              get_invoice_header_info(p_invoice_number      => p_contract_info.initial_order_number,
                                      x_invoice_header_info => lr_invoice_header_info);
            END IF;
          
          END IF;*/
          
          /****************************************
          * Get receivables application information
          ****************************************/
          
          /*IF (lr_rec_application_info.cash_receipt_id IS NULL)
          THEN
          
            lc_action := 'Calling get_receivable_application_info';
          
            get_rec_application_info(p_customer_trx_id             => lr_invoice_header_info.customer_trx_id,
                                     x_receivable_application_info => lr_rec_application_info);
          END IF;*/
          
          /************************
          * Get receipt information
          ************************/
          
          /*IF (lr_receipt_info.cash_receipt_id IS NULL)
          THEN
          
            lc_action := 'Calling get_receipt_info';
          
            get_receipt_info(p_cash_receipt_id => lr_rec_application_info.cash_receipt_id,
                             x_receipt_info    => lr_receipt_info);
          END IF;*/
            
          px_subscription_array(indx).receipt_created_flag := 'Y';
          --px_subscription_array(indx).receipt_number       := lr_receipt_info.receipt_number;

        ELSIF px_subscription_array(indx).billing_sequence_number >= lr_contract_line_info.initial_billing_sequence
        THEN

          IF ln_loop_counter = 0
          THEN

            ln_loop_counter := ln_loop_counter + 1;

            /******************************
            * Get initial order header info
            ******************************/

            lc_action := 'Calling get_order_header_info';

            IF p_contract_info.external_source = 'POS'
            THEN
              get_pos_ordt_info(p_order_number => p_contract_info.initial_order_number,
                    x_ordt_info    => lr_pos_ordt_info);
                    
              get_pos_info(p_header_id        => lr_pos_ordt_info.header_id,
                           p_orig_sys_doc_ref => p_contract_info.initial_order_number,
                           x_pos_info         => lr_pos_info);
                           
              get_order_header_info(--p_order_number      => lr_pos_info.sales_order,            --Commented for NAIT-126620.
                                    p_order_number      => p_contract_info.initial_order_number, --Added for NAIT-126620
                                    x_order_header_info => lr_order_header_info);
            ELSE
              get_order_header_info(p_order_number      => p_contract_info.initial_order_number,
                                    x_order_header_info => lr_order_header_info);
            END IF;

            /************************
            * Get invoice information
            ************************/

            lc_action := 'Calling get_invoice_header_info';

            get_invoice_header_info(p_invoice_number      => px_subscription_array(indx).invoice_number,
                                    x_invoice_header_info => lr_invoice_header_info);
            /******************************
            * Get invoice total information
            ******************************/

            lc_action := 'Calling get_invoice_total_amount_info';

            get_invoice_total_amount_info(p_customer_trx_id           => lr_invoice_header_info.customer_trx_id,
                                          x_invoice_total_amount_info => ln_invoice_total_amount_info);

            /*********************************
            * Get customer account information
            *********************************/

            lc_action := 'Calling get_customer_info';

            IF p_contract_info.external_source = 'POS'
            THEN
              get_customer_pos_info(p_aops           => p_contract_info.bill_to_osr,
                                    x_customer_info  => lr_customer_info);
            ELSE
              get_customer_info(p_cust_account_id => lr_order_header_info.sold_to_org_id,
                                x_customer_info   => lr_customer_info);
            END IF;

            /******************************
            * Setting create api attributes
            ******************************/

            lc_action := 'Setting create cash api attributes';

            lr_attrib.attribute_category := 'SALES_ACCT';
            lr_attrib.attribute1         := p_contract_info.store_number;
            lr_attrib.attribute7         := lr_order_header_info.orig_sys_document_ref;
            lr_attrib.attribute12        := p_contract_info.initial_order_number;
            lr_attrib.attribute14        := p_contract_info.card_type;

            /**********************
            * Creating cash receipt
            **********************/

            lc_action := 'calling create cash api';

            ar_receipt_api_pub.create_cash(p_api_version                => 1.0,
                                           p_init_msg_list              => fnd_api.g_true,
                                           p_commit                     => fnd_api.g_false,
                                           p_validation_level           => fnd_api.g_valid_level_full,
                                           p_currency_code              => 'USD',
                                           p_exchange_rate_type         => NULL,
                                           p_exchange_rate              => NULL,
                                           p_exchange_rate_date         => NULL,
                                           p_amount                     => ln_invoice_total_amount_info,
                                           p_receipt_number             => NULL,
                                           p_receipt_date               => SYSDATE,
                                           p_maturity_date              => NULL,
                                           p_customer_name              => NULL,
                                           p_customer_number            => lr_customer_info.account_number,
                                           p_comments                   => NULL,
                                           p_location                   => NULL,
                                           p_customer_bank_account_num  => NULL,
                                           p_customer_bank_account_name => NULL,
                                           p_receipt_method_name        => p_program_setups('receipt_method_name'),
                                           p_attribute_rec              => lr_attrib,
                                           p_org_id                     => FND_PROFILE.VALUE('org_id'),
                                           p_cr_id                      => ln_cash_receipt_id,
                                           x_return_status              => lc_return_status,
                                           x_msg_count                  => ln_msg_count,
                                           x_msg_data                   => lc_msg_data);

            logit(p_message => 'Create API error return status: ' || lc_return_status);

            /**********************
            * Get api error message
            ***********************/

            IF lc_return_status != 'S'
            THEN

              lc_error :=    'Error while creating receipt-';

              IF ln_msg_count = 1
              THEN
                lc_error :=    lc_error || lc_msg_data;
              ELSE
                FOR r IN 1 .. ln_msg_count
                LOOP
                  lc_error := lc_error || ', ' || fnd_msg_pub.get(fnd_msg_pub.g_next, fnd_api.g_false);
                END LOOP;
              END IF;

              logit(p_message => 'API error message: ' || lc_error);

              RAISE le_processing;

            END IF;

            /*****************
            * Get receipt info
            *****************/

            lc_action := 'Calling get_receipt_info';

            get_receipt_info(p_cash_receipt_id => ln_cash_receipt_id,
                             x_receipt_info    => lr_receipt_info);

            /*************************
            * Apply receipt to invoice
            *************************/

            lc_return_status  := NULL;
            ln_msg_count      := 0;
            lc_msg_data       := NULL;

            ar_receipt_api_pub.APPLY(p_api_version      => 1.0,
                                     p_init_msg_list    => fnd_api.g_true,
                                     p_commit           => fnd_api.g_false,
                                     p_validation_level => fnd_api.g_valid_level_full,
                                     x_return_status    => lc_return_status,
                                     x_msg_count        => ln_msg_count,
                                     x_msg_data         => lc_msg_data,
                                     p_cash_receipt_id  => ln_cash_receipt_id,
                                     p_customer_trx_id  => lr_invoice_header_info.customer_trx_id,
                                     p_amount_applied   => ln_invoice_total_amount_info,
                                     p_discount         => NULL,
                                     p_apply_date       => SYSDATE);

            logit(p_message => 'Apply API error return status: ' || lc_return_status);

            /**********************
            * Get api error message
            **********************/

            IF lc_return_status != 'S'
            THEN

              lc_error :=    'Error while applying receipt-';

              IF ln_msg_count = 1
              THEN
                lc_error :=    lc_error || lc_msg_data;
              ELSE
                FOR r IN 1 .. ln_msg_count
                LOOP
                  lc_error := lc_error || ', ' || fnd_msg_pub.get(fnd_msg_pub.g_next, fnd_api.g_false);
                END LOOP;
              END IF;

              logit(p_message => 'API error message: ' || lc_error);

              RAISE le_processing;

            END IF;

            lc_receipt_created_flag := 'Y';
            lc_receipt_number       := lr_receipt_info.receipt_number;

          END IF; -- IF ln_loop_counter = 0

          px_subscription_array(indx).receipt_created_flag := lc_receipt_created_flag;
          px_subscription_array(indx).receipt_number       := lc_receipt_number;

        END IF; -- IF px_subscription_array(indx).billing_sequene_number != 1

        lc_action := 'Calling update_subscription_info';

        update_subscription_info(px_subscription_info => px_subscription_array(indx));

      EXCEPTION
      WHEN le_processing
      THEN

        lr_subscription_error_info                         := NULL;
        lr_subscription_error_info.contract_id             := px_subscription_array(indx).contract_id;
        lr_subscription_error_info.contract_number         := px_subscription_array(indx).contract_number;
        lr_subscription_error_info.contract_line_number    := NULL;
        lr_subscription_error_info.billing_sequence_number := px_subscription_array(indx).billing_sequence_number;
        lr_subscription_error_info.error_module            := lc_procedure_name;
        lr_subscription_error_info.error_message           := SUBSTR('Action: ' || lc_action || ' Error: ' || lc_error, 1, gc_max_err_size);
        lr_subscription_error_info.creation_date           := SYSDATE;

        lc_action := 'Calling insert_subscription_error_info';

        insert_subscription_error_info(p_subscription_error_info => lr_subscription_error_info);

        lc_receipt_created_flag := 'E';
        lc_error                := lr_subscription_error_info.error_message;

        RAISE le_processing;

       WHEN OTHERS
       THEN

        lr_subscription_error_info                         := NULL;
        lr_subscription_error_info.contract_id             := px_subscription_array(indx).contract_id;
        lr_subscription_error_info.contract_number         := px_subscription_array(indx).contract_number;
        lr_subscription_error_info.contract_line_number    := NULL;
        lr_subscription_error_info.billing_sequence_number := px_subscription_array(indx).billing_sequence_number;
        lr_subscription_error_info.error_module            := lc_procedure_name;
        lr_subscription_error_info.error_message           := SUBSTR('Action: ' || lc_action || ' Error: ' || SQLCODE || ' ' || SQLERRM, 1, gc_max_err_size);
        lr_subscription_error_info.creation_date           := SYSDATE;

        lc_action := 'Calling insert_subscription_error_info';

        insert_subscription_error_info(p_subscription_error_info => lr_subscription_error_info);

        lc_receipt_created_flag := 'E';
        lc_error                := lr_subscription_error_info.error_message;

        RAISE le_processing;

      END;

    END LOOP;

    COMMIT;

    exiting_sub(p_procedure_name => lc_procedure_name);

  EXCEPTION
  WHEN le_skip
  THEN
    logit(p_message => 'Skipping: ' || lc_error);
  WHEN le_processing
  THEN

    ROLLBACK TO sp_transaction;

    FOR indx IN 1 .. px_subscription_array.COUNT
    LOOP

      px_subscription_array(indx).receipt_created_flag := lc_receipt_created_flag;

      lc_action := 'Calling update_subscription_info to update with error info';

      update_subscription_info(px_subscription_info => px_subscription_array(indx));

    END LOOP;

    exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => TRUE);

    RAISE_APPLICATION_ERROR(-20101, 'PROCEDURE: ' || lc_procedure_name || ' ' || lc_error );

  WHEN OTHERS
  THEN

    ROLLBACK TO sp_transaction;

    FOR indx IN 1 .. px_subscription_array.COUNT
    LOOP

      px_subscription_array(indx).receipt_created_flag := 'E';

      lc_action := 'Calling update_subscription_info to update with error info';

      update_subscription_info(px_subscription_info => px_subscription_array(indx));

    END LOOP;

    exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => TRUE);

    RAISE_APPLICATION_ERROR(-20101, 'PROCEDURE: ' || lc_procedure_name || ' Action: ' || lc_action || ' SQLCODE: ' || SQLCODE || ' SQLERRM: ' || SQLERRM);

  END process_receipt;

  /****************************************
  * Helper procedure to process ordt record
  ****************************************/

  PROCEDURE process_ordt_info(p_program_setups      IN            gt_translation_values,
                              p_contract_info       IN            xx_ar_contracts%ROWTYPE,
                              px_subscription_array IN OUT NOCOPY subscription_table)
  IS

    lc_procedure_name    CONSTANT  VARCHAR2(61) := gc_package_name || '.' || 'process_ordt_info';

    lt_parameters                  gt_input_parameters;

    lc_action                      VARCHAR2(1000);

    lc_error                       VARCHAR2(2000);

    ln_loop_counter                NUMBER := 0;

    lr_ordt_info                   xx_ar_order_receipt_dtl%ROWTYPE;

    lr_order_header_info           oe_order_headers_all%ROWTYPE;

    lr_bill_to_cust_acct_site_info hz_cust_acct_sites_all%ROWTYPE;

    lr_invoice_header_info         ra_customer_trx_all%ROWTYPE;

    ln_invoice_total_amount_info   ra_customer_trx_lines_all.extended_amount%TYPE;

    lr_rec_application_info        ar_receivable_applications_all%ROWTYPE;

    lr_customer_info               hz_cust_accounts%ROWTYPE;

    lr_attrib                      ar_receipt_api_pub.attribute_rec_type;

    ln_cash_receipt_id             ar_cash_receipts_all.cash_receipt_id%TYPE;

    lr_receipt_info                ar_cash_receipts_all%ROWTYPE;

    lr_subscription_error_info     xx_ar_subscriptions_error%ROWTYPE;

    lc_ordt_staged_flag            xx_ar_subscriptions.ordt_staged_flag%TYPE;

    ln_order_payment_id            xx_ar_subscriptions.order_payment_id%TYPE;

    lc_return_status               VARCHAR2(1)     := NULL;

    lc_msg_data                    VARCHAR2(2000)  := NULL;

    ln_msg_count                   NUMBER          := 0;

    ln_receipt_count               NUMBER          := 0;

    le_skip                        EXCEPTION;

    le_processing                  EXCEPTION;
    
    lr_contract_line_info          xx_ar_contract_lines%ROWTYPE;
    
    lt_translation_info            xx_fin_translatevalues%ROWTYPE;
    
    lr_receipt_method_id           ar_receipt_methods.receipt_method_id%TYPE;
    
    lr_pos_ordt_info               xx_ar_order_receipt_dtl%ROWTYPE;
    
    lr_pos_info                    xx_ar_pos_inv_order_ref%ROWTYPE;

  BEGIN

    entering_sub(p_procedure_name  => lc_procedure_name,
                 p_parameters      => lt_parameters);

    /*****************************************************************************
    * Validate we have all the information in subscriptions needed to process ordt
    *****************************************************************************/

    lc_action := 'Looping thru subscription array for prevalidation';

    FOR indx IN 1 .. px_subscription_array.COUNT
    LOOP

      /**************************
      * Validate receipt was done
      **************************/

      IF px_subscription_array(indx).receipt_created_flag != 'Y'
      THEN

        lc_error := 'Receipt not completed';
        RAISE le_skip;

      END IF;

      /****************************************
      * Validate we are ready to create receipt
      ****************************************/

      IF px_subscription_array(indx).ordt_staged_flag NOT IN ('N', 'E')
      THEN
        lc_error := 'ORDT flag: ' || px_subscription_array(indx).ordt_staged_flag;
        RAISE le_skip;
      END IF;
      
      /*************************************
      * Validate we are read to perform auth
      *************************************/
      IF p_contract_info.payment_type = 'AB'
      THEN
        lc_error := 'Payment Type is: ' || p_contract_info.payment_type;
        RAISE le_skip;
      END IF;

    END LOOP;

    lc_action := 'Setting transaction savepoint';

    SAVEPOINT sp_transaction;

    /*******************************************************************************
    * Loop thru all the information in subscriptions for inserting records into ORDT
    *******************************************************************************/

    lc_action := 'Looping thru subscription array';

    FOR indx IN 1 .. px_subscription_array.COUNT
    LOOP
      BEGIN
      
        /******************************
        * Get contract line information
        ******************************/

        lc_action := 'Calling get_contract_line_info process_ordt_info';

        get_contract_line_info(p_contract_id          => px_subscription_array(indx).contract_id,
                               p_contract_line_number => px_subscription_array(indx).contract_line_number,
                               x_contract_line_info   => lr_contract_line_info);

        IF  px_subscription_array(indx).billing_sequence_number < lr_contract_line_info.initial_billing_sequence
        --AND lr_contract_line_info.program = 'SS'
        THEN

          /************************
          * Get invoice information
          ************************/
          
          /*IF (lr_invoice_header_info.customer_trx_id IS NULL)
          THEN
          
            lc_action := 'Calling get_invoice_header_info';
          
            IF p_contract_info.external_source = 'POS'
            THEN
              get_pos_ordt_info(p_order_number => p_contract_info.initial_order_number,
                    x_ordt_info    => lr_pos_ordt_info);
                    
              get_pos_info(p_header_id        => lr_pos_ordt_info.header_id,
                           p_orig_sys_doc_ref => p_contract_info.initial_order_number,
                           x_pos_info         => lr_pos_info);
                           
              get_invoice_header_info(p_invoice_number      => lr_pos_info.summary_trx_number,
                                      x_invoice_header_info => lr_invoice_header_info);
            ELSE
              get_invoice_header_info(p_invoice_number      => p_contract_info.initial_order_number,
                                      x_invoice_header_info => lr_invoice_header_info);
            END IF;
          
          END IF;*/
          
          /****************************************
          * Get receivables application information
          ****************************************/
          
          /*IF (lr_rec_application_info.cash_receipt_id IS NULL)
          THEN
          
            lc_action := 'Calling get_receivable_application_info';
          
            get_rec_application_info(p_customer_trx_id             => lr_invoice_header_info.customer_trx_id,
                                     x_receivable_application_info => lr_rec_application_info);
          END IF;*/
          
          /*********************
          * Get ORDT information
          *********************/
          
          /*IF (lr_ordt_info.order_payment_id IS NULL)
          THEN
            lc_action := 'Calling get_ordt_info';
            
            get_ordt_info(p_cash_receipt_id  => lr_rec_application_info.cash_receipt_id,
                          x_ordt_info        => lr_ordt_info);
          END IF;*/
            
          px_subscription_array(indx).ordt_staged_flag := 'Y';
          --px_subscription_array(indx).order_payment_id  := lr_ordt_info.order_payment_id;

        ELSIF px_subscription_array(indx).billing_sequence_number >= lr_contract_line_info.initial_billing_sequence
        THEN

          IF ln_loop_counter = 0
          THEN

            ln_loop_counter := ln_loop_counter + 1;

            /******************************
            * Get initial order header info
            ******************************/

            lc_action := 'Calling get_order_header_info';

            IF p_contract_info.external_source = 'POS'
            THEN
              get_pos_ordt_info(p_order_number => p_contract_info.initial_order_number,
                                x_ordt_info    => lr_pos_ordt_info);
                    
              get_pos_info(p_header_id        => lr_pos_ordt_info.header_id,
                           p_orig_sys_doc_ref => p_contract_info.initial_order_number,
                           x_pos_info         => lr_pos_info);
                           
              get_order_header_info(--p_order_number      => lr_pos_info.sales_order,            --Commented for NAIT-126620.
                                    p_order_number      => p_contract_info.initial_order_number, --Added for NAIT-126620
                                    x_order_header_info => lr_order_header_info);
            ELSE
              get_order_header_info(p_order_number      => p_contract_info.initial_order_number,
                                    x_order_header_info => lr_order_header_info);
            END IF;

            /*************************************************
            * Get initial order BILL_TO cust account site info
            *************************************************/

            lc_action := 'Calling get_cust_account_site_info for BILL_TO';

            IF p_contract_info.external_source = 'POS'
            THEN
              get_customer_pos_info(p_aops           => p_contract_info.bill_to_osr,
                                    x_customer_info  => lr_customer_info);
                                  
              get_cust_site_pos_info(p_customer_id     => lr_customer_info.cust_account_id,
                                     x_cust_site_info  => lr_bill_to_cust_acct_site_info);
            ELSE
              get_cust_account_site_info(p_site_use_id            => lr_order_header_info.invoice_to_org_id,
                                         p_site_use_code          => 'BILL_TO',
                                         x_cust_account_site_info => lr_bill_to_cust_acct_site_info);
            END IF;

            /************************
            * Get invoice information
            ************************/

            lc_action := 'Calling get_invoice_header_info';

            get_invoice_header_info(p_invoice_number      => px_subscription_array(indx).invoice_number,
                                    x_invoice_header_info => lr_invoice_header_info);
            /******************************
            * Get invoice total information
            ******************************/

            lc_action := 'Calling get_invoice_total_amount_info';

            get_invoice_total_amount_info(p_customer_trx_id           => lr_invoice_header_info.customer_trx_id,
                                          x_invoice_total_amount_info => ln_invoice_total_amount_info);

            /*********************************
            * Get customer account information
            *********************************/

            lc_action := 'Calling get_customer_info';

            IF p_contract_info.external_source = 'POS'
            THEN
              get_customer_pos_info(p_aops           => p_contract_info.bill_to_osr,
                                    x_customer_info  => lr_customer_info);
            ELSE
              get_customer_info(p_cust_account_id => lr_order_header_info.sold_to_org_id,
                                x_customer_info   => lr_customer_info);
            END IF;
    
            /************************
            * Get receipt method info
            ************************/

            lc_action := 'Calling get_receipt_method_info';

            get_receipt_method_info(p_receipt_method_name => p_program_setups('receipt_method_name'),
                                    x_receipt_method_id   => lr_receipt_method_id);
                             
            /*****************
            * Get receipt info
            *****************/

            lc_action := 'Calling get_receipt_info';

            get_receipt_info(p_receipt_number    => px_subscription_array(indx).receipt_number,
                             p_receipt_method_id => lr_receipt_method_id,
                             x_receipt_info      => lr_receipt_info);

            /*********************
            * Populate ORDT record
            *********************/

            lc_action := 'Populating ordt record';

            lr_ordt_info.order_payment_id           := xx_ar_order_payment_id_s.NEXTVAL;
            lr_ordt_info.order_number               := NULL;
            lr_ordt_info.orig_sys_document_ref      := NULL;
            lr_ordt_info.orig_sys_payment_ref       := NULL;
            lr_ordt_info.payment_number             := 1;
            lr_ordt_info.header_id                  := NULL;
            lr_ordt_info.order_source               := NULL;
            lr_ordt_info.order_type                 := NULL;
            lr_ordt_info.cash_receipt_id            := lr_receipt_info.cash_receipt_id;
            lr_ordt_info.receipt_number             := lr_receipt_info.receipt_number;
            lr_ordt_info.customer_id                := lr_customer_info.cust_account_id;--lr_order_header_info.sold_to_org_id;
            lr_ordt_info.store_number               := p_contract_info.store_number;
            lr_ordt_info.credit_card_number         := px_subscription_array(indx).settlement_card;
            lr_ordt_info.credit_card_holder_name    := p_contract_info.card_holder_name;
            lr_ordt_info.payment_amount             := ln_invoice_total_amount_info;
            lr_ordt_info.receipt_method_id          := lr_receipt_info.receipt_method_id;
            lr_ordt_info.cc_auth_manual             := NULL;
            lr_ordt_info.merchant_number            := NULL;
            lr_ordt_info.cc_auth_ps2000             := NULL;
            lr_ordt_info.allied_ind                 := NULL;
            lr_ordt_info.payment_set_id             := NULL;
            lr_ordt_info.process_code               := 'SERVICE-CONTRACTS';
            lr_ordt_info.cc_mask_number             := px_subscription_array(indx).settlement_cc_mask;
            lr_ordt_info.od_payment_type            := NULL;
            lr_ordt_info.check_number               := NULL;
            lr_ordt_info.org_id                     := FND_PROFILE.VALUE('org_id');
            lr_ordt_info.request_id                 := NVL(FND_GLOBAL.CONC_REQUEST_ID, -1);
            lr_ordt_info.imp_file_name              := NULL;
            lr_ordt_info.creation_date              := SYSDATE;
            lr_ordt_info.created_by                 := FND_GLOBAL.USER_ID;
            lr_ordt_info.last_update_date           := SYSDATE;
            lr_ordt_info.last_updated_by            := FND_GLOBAL.USER_ID;
            lr_ordt_info.matched                    := 'N';
            lr_ordt_info.ship_from                  := NULL;
            lr_ordt_info.receipt_status             := 'OPEN';
            lr_ordt_info.customer_receipt_reference := px_subscription_array(indx).invoice_number;
            lr_ordt_info.credit_card_approval_code  := px_subscription_array(indx).auth_code;
            lr_ordt_info.customer_site_billto_id    := lr_bill_to_cust_acct_site_info.cust_acct_site_id;
            lr_ordt_info.receipt_date               := lr_receipt_info.receipt_date;
            lr_ordt_info.sale_type                  := 'SALE';
            lr_ordt_info.additional_auth_codes      := NULL;
            lr_ordt_info.process_date               := px_subscription_array(indx).billing_date;
            lr_ordt_info.single_pay_ind             := 'N';
            lr_ordt_info.currency_code              := NVL(px_subscription_array(indx).currency_code, 'USD');
            lr_ordt_info.last_update_login          := FND_GLOBAL.USER_ID;
            lr_ordt_info.cleared_date               := NULL;
            lr_ordt_info.identifier                 := px_subscription_array(indx).settlement_label;
            lr_ordt_info.settlement_error_message   := NULL;
            lr_ordt_info.original_cash_receipt_id   := NULL;
            lr_ordt_info.mpl_order_id               := px_subscription_array(indx).contract_number;
            lr_ordt_info.emv_card                   := 'N';
            lr_ordt_info.emv_terminal               := NULL;
            lr_ordt_info.emv_transaction            := 'N';
            lr_ordt_info.emv_offline                := 'N';
            lr_ordt_info.emv_fallback               := 'N';
            lr_ordt_info.emv_tvr                    := NULL;
            
            /***********************
            * Determine payment type
            ***********************/

            IF p_contract_info.payment_type = 'CreditCard'
            THEN
              lr_ordt_info.payment_type_code := 'CREDIT_CARD';
            ELSIF p_contract_info.payment_type = 'PLCC'
            THEN
              lr_ordt_info.payment_type_code := 'CREDIT_CARD';
            ELSIF p_contract_info.payment_type = 'MasterPass'
            THEN
              lr_ordt_info.payment_type_code := 'CREDIT_CARD';
            ELSIF p_contract_info.payment_type = 'PAYPAL'
            THEN
              lr_ordt_info.payment_type_code := 'CASH';
            END IF;


            /********************
            * Determine card code
            ********************/

            IF  p_contract_info.card_type = 'PLCC'
            THEN

              lc_action := 'Calling get_plcc_card_code';

              get_plcc_card_code(p_card_bin_number => SUBSTR(px_subscription_array(indx).settlement_cc_mask, 1, 6),
                                 x_card_code       => lr_ordt_info.credit_card_code);
            ELSE
              lr_ordt_info.credit_card_code := p_contract_info.card_type;
            END IF;

            /****************************
            * Format card expiration date
            ****************************/
            lc_action := 'Format card expiration date';
            IF (p_contract_info.card_expiration_date IS NOT NULL)
            THEN
              lr_ordt_info.credit_card_expiration_date := p_contract_info.card_expiration_date;
            END IF;

            /************************
            * Determine remitted flag
            ************************/
            lc_action := 'Determine remitted flag';
            IF p_contract_info.payment_type = 'PAYPAL'
            THEN
              lr_ordt_info.remitted := 'Y';
            ELSE
              lr_ordt_info.remitted := 'N';
            END IF;

            /*************************************
            * Formatting credit card approval date
            *************************************/
            lc_action := 'Formatting credit card approval date';
            IF px_subscription_array(indx).auth_datetime IS NOT NULL
            THEN
              lr_ordt_info.credit_card_approval_date := TO_DATE(SUBSTR(px_subscription_array(indx).auth_datetime, 1, (INSTR(px_subscription_array(indx).auth_datetime, 'T') - 1) ), 'YYYY-MM-DD');
            END IF;

            /*********************
            * Determine token flag
            *********************/
            lc_action := 'Determine token flag';
            IF p_contract_info.payment_type = 'CreditCard'
            THEN
              lr_ordt_info.token_flag := 'Y';
            ELSIF p_contract_info.payment_type = 'MasterPass'
            THEN
              lr_ordt_info.token_flag := 'Y';
            ELSE
              lr_ordt_info.token_flag := 'N';
            END IF;

            /***********************
            * Determine wallet type
            ***********************/
            lc_action := 'Determine wallet type';
            IF p_contract_info.payment_type = 'MasterPass'
            THEN
              lr_ordt_info.wallet_type := 'P';
            ELSE
              IF p_program_setups('cof_check_flag') = 'Y'
              THEN
                IF TRUNC(px_subscription_array(indx).initial_auth_attempt_date) = TRUNC(px_subscription_array(indx).last_auth_attempt_date)
                THEN
                  lr_ordt_info.wallet_type := p_program_setups('subscription_subsequent');
                ELSE
                  lr_ordt_info.wallet_type := p_program_setups('subscription_resubmit');
                END IF;
              ELSE
                lr_ordt_info.wallet_type := NULL;
              END IF;
            END IF;

            /********************
            * Determine wallet id
            ********************/
            lc_action := 'Determine wallet id';
            IF p_contract_info.payment_type = 'MasterPass'
            THEN
              lr_ordt_info.wallet_id := p_contract_info.payment_identifier;
            ELSE
              lr_ordt_info.wallet_id := NULL;
            END IF;

            lc_ordt_staged_flag := 'Y';
            ln_order_payment_id := lr_ordt_info.order_payment_id;

            /*******************
            * Insert ORDT record
            *******************/

            lc_action := 'Calling insert_ordt_info';

            insert_ordt_info(p_ordt_info => lr_ordt_info);

          END IF; -- IF ln_loop_counter = 0

          px_subscription_array(indx).ordt_staged_flag := lc_ordt_staged_flag;
          px_subscription_array(indx).order_payment_id := ln_order_payment_id;

        END IF; -- IF px_subscription_array(indx).billing_sequene_number != 1

        lc_action := 'Calling update_subscription_info';

        update_subscription_info(px_subscription_info => px_subscription_array(indx));

      EXCEPTION
      WHEN le_processing
      THEN

        ROLLBACK TO sp_transaction;

        lr_subscription_error_info                         := NULL;
        lr_subscription_error_info.contract_id             := px_subscription_array(indx).contract_id;
        lr_subscription_error_info.contract_number         := px_subscription_array(indx).contract_number;
        lr_subscription_error_info.contract_line_number    := NULL;
        lr_subscription_error_info.billing_sequence_number := px_subscription_array(indx).billing_sequence_number;
        lr_subscription_error_info.error_module            := lc_procedure_name;
        lr_subscription_error_info.error_message           := SUBSTR('Action: ' || lc_action || ' Error: ' || lc_error, 1, gc_max_err_size);
        lr_subscription_error_info.creation_date           := SYSDATE;

        lc_action := 'Calling insert_subscription_error_info';

        insert_subscription_error_info(p_subscription_error_info => lr_subscription_error_info);

        lc_ordt_staged_flag := 'E';
        lc_error            := lr_subscription_error_info.error_message;

        RAISE le_processing;

       WHEN OTHERS
       THEN

        ROLLBACK TO sp_transaction;

        lr_subscription_error_info                         := NULL;
        lr_subscription_error_info.contract_id             := px_subscription_array(indx).contract_id;
        lr_subscription_error_info.contract_number         := px_subscription_array(indx).contract_number;
        lr_subscription_error_info.contract_line_number    := NULL;
        lr_subscription_error_info.billing_sequence_number := px_subscription_array(indx).billing_sequence_number;
        lr_subscription_error_info.error_module            := lc_procedure_name;
        lr_subscription_error_info.error_message           := SUBSTR('Action: ' || lc_action || ' Error: ' || SQLCODE || ' ' || SQLERRM, 1, gc_max_err_size);
        lr_subscription_error_info.creation_date           := SYSDATE;

        lc_action := 'Calling insert_subscription_error_info';

        insert_subscription_error_info(p_subscription_error_info => lr_subscription_error_info);

        lc_ordt_staged_flag := 'E';
        lc_error            := lr_subscription_error_info.error_message;

        RAISE le_processing;

      END;

    END LOOP;

    COMMIT;

    exiting_sub(p_procedure_name => lc_procedure_name);

  EXCEPTION
  WHEN le_skip
  THEN
    logit(p_message => 'Skipping: ' || lc_error);
  WHEN le_processing
  THEN
    FOR indx IN 1 .. px_subscription_array.COUNT
    LOOP

      px_subscription_array(indx).ordt_staged_flag := lc_ordt_staged_flag;

      lc_action := 'Calling update_subscription_info to update with error info';

      update_subscription_info(px_subscription_info => px_subscription_array(indx));
    END LOOP;

    exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => TRUE);

    RAISE_APPLICATION_ERROR(-20101, 'PROCEDURE: ' || lc_procedure_name || ' ' || lc_error);
  WHEN OTHERS
  THEN
    FOR indx IN 1 .. px_subscription_array.COUNT
    LOOP

      px_subscription_array(indx).ordt_staged_flag := 'E';

      lc_action := 'Calling update_subscription_info to update with error info';

      update_subscription_info(px_subscription_info => px_subscription_array(indx));
    END LOOP;

    exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => TRUE);

    RAISE_APPLICATION_ERROR(-20101, 'PROCEDURE: ' || lc_procedure_name || ' Action: ' || lc_action || ' SQLCODE: ' || SQLCODE || ' SQLERRM: ' || SQLERRM);

  END process_ordt_info;

  /*****
  * MAIN
  *****/

  PROCEDURE process_eligible_subscriptions(errbuff            OUT VARCHAR2,
                                           retcode            OUT NUMBER,
                                           p_debug_flag       IN  VARCHAR2 DEFAULT 'N',
                                           p_populate_invoice IN  VARCHAR2,
                                           p_create_receipt   IN  VARCHAR2,
                                           p_email_flag       IN  VARCHAR2,
                                           p_history_flag     IN  VARCHAR2)
  IS
    CURSOR c_eligible_contracts
    IS
      SELECT DISTINCT contract_id,
                      billing_sequence_number
      FROM   xx_ar_subscriptions
      WHERE  (       ordt_staged_flag  IN ('N', 'E')
              OR     email_sent_flag   IN ('N', 'E')
              OR     history_sent_flag IN ('N', 'E') )
      ORDER BY contract_id             ASC,
               billing_sequence_number ASC;

    lc_procedure_name           CONSTANT VARCHAR2(61) := gc_package_name || '.' || 'process_eligible_subscriptions';

    lt_parameters               gt_input_parameters;

    lt_program_setups           gt_translation_values;

    lr_contract_info            xx_ar_contracts%ROWTYPE;

    lt_subscription_array       subscription_table;

    lc_transaction              VARCHAR2(5000);

    lc_action                   VARCHAR2(1000);

    lt_item_cost_tab            item_cost_tab;

    ln_records_passed           NUMBER := 0;

    ln_records_failed           NUMBER := 0;

  BEGIN

    lt_parameters('p_debug_flag')       := p_debug_flag;
    lt_parameters('p_populate_invoice') := p_populate_invoice;
    lt_parameters('p_create_receipt')   := p_create_receipt;
    lt_parameters('p_email_flag')       := p_email_flag;
    lt_parameters('p_history_flag')     := p_history_flag;

    entering_main(p_procedure_name   => lc_procedure_name,
                  p_rice_identifier  => 'E7044',
                  p_debug_flag       => p_debug_flag,
                  p_parameters       => lt_parameters);

    /************************
    * Setting NLS Date Format
    ************************/
    EXECUTE IMMEDIATE 'ALTER SESSION SET NLS_DATE_FORMAT = ''DD-MON-YYYY HH24:MI:SS''';

    /******************************
    * Initialize program variables.
    ******************************/

    retcode := 0;

    lc_action := 'Calling get_program_setups';

    get_program_setups(x_program_setups => lt_program_setups);

    /*******************************************************************************
    * If passed in p_debug_flag IS N, check if debug is enabled in translation table
    *******************************************************************************/

    IF (p_debug_flag != 'Y' AND lt_program_setups('enable_debug') = 'Y')
    THEN

      lc_action := 'Calling set_debug';

      set_debug(p_debug_flag => lt_program_setups('enable_debug'));

    END IF;

    lc_action := 'Calling mo_global.set_policy_context';

    mo_global.set_policy_context('S', fnd_profile.VALUE('org_id') );
    
    /***********************************************
    *  Loop thru pending contracts/billing sequences
    ***********************************************/

    lc_action := 'Calling c_eligible_contracts cursor';

    FOR eligible_contract_rec IN c_eligible_contracts
    LOOP

      BEGIN

        /************************************************************************
        * Keep track of the contract number and billing sequence being worked on.
        ************************************************************************/

        lc_transaction := 'Processing contract_id: ' || eligible_contract_rec.contract_id ||
                          ' billing_sequence_number: '   || eligible_contract_rec.billing_sequence_number;

        logit(p_message => 'Transaction: ' || lc_transaction);

        /***********
        * Initialize
        ***********/

        /**************************************
        * Get contract header level information
        **************************************/

        lc_action := 'Calling get_contract_info';

        get_contract_info(p_contract_id     => eligible_contract_rec.contract_id,
                          x_contract_info   => lr_contract_info);

        /********************************************
        * Get all the associated subscription records
        ********************************************/

        lt_subscription_array.delete();

        lc_action := 'Calling get_subscription_array';

        get_subscription_array(p_contract_id             => eligible_contract_rec.contract_id,
                               p_billing_sequence_number => eligible_contract_rec.billing_sequence_number,
                               x_subscription_array      => lt_subscription_array);

        /**********************
        * Process the item cost
        **********************/

        lc_action := 'Calling process_item_cost';

        process_item_cost(p_rms_db_link         => lt_program_setups('rms_dba_link'),
                          px_subscription_array => lt_subscription_array,
                          px_item_cost_tab      => lt_item_cost_tab);
        
        /****************
        * calculating tax 
        ****************/

        lc_action := 'Calling process_tax';

        process_tax(p_program_setups      => lt_program_setups,
                    p_contract_info       => lr_contract_info,
                    px_subscription_array => lt_subscription_array);
                      

        /***************************
        * Populate invoice interface
        ***************************/

        IF p_populate_invoice = 'Y'
        THEN
         lc_action := 'Calling populate_invoice_interface';

          populate_invoice_interface(p_program_setups      => lt_program_setups,
                                     p_contract_info       => lr_contract_info,
                                     px_subscription_array => lt_subscription_array);

        END IF;

        IF p_create_receipt = 'Y'
        THEN

          /************************
          * Get invoice information
          ************************/

          lc_action := 'Calling get_invoice_information';
     
          get_invoice_information(p_contract_info       => lr_contract_info,
                                  px_subscription_array => lt_subscription_array);

          /*************************
          * Get trans id information
          *************************/

          /*IF lt_program_setups('cof_check_flag') = 'Y'
          THEN
            lc_action := 'Calling get_cc_trans_id_information';
            
            get_cc_trans_id_information(p_program_setups      => lt_program_setups,
                                        p_contract_info       => lr_contract_info,
                                        px_subscription_array => lt_subscription_array);
          END IF;*/
                                  
          /**************************************
          * Get contract header level information
          **************************************/
          
          /*lc_action := 'Calling get_contract_info';
          
          get_contract_info(p_contract_id     => eligible_contract_rec.contract_id,
                            x_contract_info   => lr_contract_info);*/

          /**********************
          * Process authorization
          **********************/
          lc_action := 'Calling process_authorization';

          process_authorization(p_program_setups      => lt_program_setups,
                                p_contract_info       => lr_contract_info,
                                px_subscription_array => lt_subscription_array);

          /**************************************
          * Get contract header level information
          **************************************/
          
          lc_action := 'Calling get_contract_info';
          
          get_contract_info(p_contract_id     => eligible_contract_rec.contract_id,
                            x_contract_info   => lr_contract_info);

          /****************
          * Process receipt
          ****************/

          lc_action := 'Calling process_receipt';
     
          process_receipt(p_program_setups      => lt_program_setups,
                          p_contract_info       => lr_contract_info,
                          px_subscription_array => lt_subscription_array);

          /**************
          * Populate ORDT
          **************/

          lc_action := 'Calling populate_ordt';

          process_ordt_info(p_program_setups      => lt_program_setups,
                            p_contract_info       => lr_contract_info,
                            px_subscription_array => lt_subscription_array);

        END IF;

        /*****************************
        * Send recurring billing email
        *****************************/
        IF p_email_flag = 'Y'
        THEN

          lc_action := 'Calling send_billing_email';

          send_billing_email(p_program_setups      => lt_program_setups,
                             p_contract_info       => lr_contract_info,
                             px_subscription_array => lt_subscription_array);

        END IF;

        /******************************
        * Send recurring billing history.
        ******************************/
        IF p_history_flag = 'Y'
        THEN

          lc_action := 'Calling send_billing_history';

          send_billing_history(p_program_setups      => lt_program_setups,
                               p_contract_info       => lr_contract_info,
                               px_subscription_array => lt_subscription_array);

        END IF;

        ln_records_passed := ln_records_passed + 1;

      EXCEPTION
      WHEN OTHERS
      THEN

        ln_records_failed := ln_records_failed + 1;

        errbuff := 'Error encountered. Please check logs';

        logit(p_message => 'ERROR Transaction: ' || lc_transaction || ' Action: ' || lc_action || ' SQLCODE: ' || SQLCODE || ' SQLERRM: ' || SQLERRM,
              p_force   => TRUE);
        logit(p_message      => '-----------------------------------------------',
              p_force   => TRUE);

      END;
    END LOOP;

    logit(p_message => 'Records passed: ' || ln_records_passed);
    logit(p_message => 'Records failed: ' || ln_records_failed);
    logit(p_message => 'Total records: '  || (ln_records_passed + ln_records_failed));

    /************************************************************************************************
    * Mark the job Error or Warning, based on number of authorization failures. *** Please review ***
    *************************************************************************************************/
        
    IF (((ln_records_failed/(ln_records_passed + ln_records_failed)) * 100) > 25 AND ((ln_records_failed/(ln_records_passed + ln_records_failed)) * 100) < 60) THEN
      retcode := 1;
    ELSIF (((ln_records_failed/(ln_records_passed + ln_records_failed)) * 100) >= 60) THEN 
      retcode := 2;
    END IF;
    
    exiting_sub(p_procedure_name => lc_procedure_name);

  EXCEPTION
  WHEN OTHERS
  THEN
    retcode := 2;

    errbuff := 'Error encountered. Please check logs';

    logit(p_message => 'ERROR Transaction: ' || lc_transaction || ' Action: ' || lc_action || ' SQLCODE: ' || SQLCODE || ' SQLERRM: ' || SQLERRM,
          p_force   => TRUE);
    logit(p_message      => '-----------------------------------------------',
          p_force   => TRUE);

    exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => TRUE);

  END process_eligible_subscriptions;

  /******************************
  *  Import Contract Information
  ******************************/

   PROCEDURE import_contract_info(errbuff      OUT VARCHAR2,
                                 retcode      OUT NUMBER,
                                 p_debug_flag IN  VARCHAR2 DEFAULT 'N'
                                 )
  IS
    CURSOR c_eligible_contracts
    IS
      SELECT contract_id,
             contract_number,
             contract_major_version,
             SUM(total_amount) total_contract_amount
      FROM     xx_ar_contracts_gtt
      GROUP BY contract_id,
               contract_number,
               contract_major_version
      ORDER BY contract_number,
               contract_major_version;

    CURSOR c_eligible_contract_lines(p_contract_id            IN xx_ar_contracts_gtt.contract_id%TYPE,
                                     p_contract_number        IN xx_ar_contracts_gtt.contract_number%TYPE,
                                     p_contract_major_version IN xx_ar_contracts_gtt.contract_major_version%TYPE)
    IS
      SELECT *
      FROM   xx_ar_contracts_gtt
      WHERE  contract_id            = p_contract_id
      AND    contract_number        = p_contract_number
      AND    contract_major_version = p_contract_major_version
      ORDER BY creation_date;

    lc_procedure_name           CONSTANT VARCHAR2(61) := gc_package_name || '.' || 'import_contract_info';

    lt_parameters               gt_input_parameters;

    lt_program_setups           gt_translation_values;

    lr_contract_info            xx_ar_contracts%ROWTYPE;

    lr_contract_line_info       xx_ar_contract_lines%ROWTYPE;

    lb_header_processed         BOOLEAN  := FALSE;

    lc_transaction              VARCHAR2(5000);

    lc_transaction_detail       VARCHAR2(1000);

    lc_action                   VARCHAR2(1000);

    ln_records_passed           NUMBER := 0;

    ln_records_failed           NUMBER := 0;

  BEGIN

    lt_parameters('p_debug_flag') := p_debug_flag;

    entering_main(p_procedure_name   => lc_procedure_name,
                  p_rice_identifier  => 'E7044',
                  p_debug_flag       => p_debug_flag,
                  p_parameters       => lt_parameters);

    retcode := 0;

    /******************************
    * Initialize program variables.
    ******************************/

    get_program_setups(x_program_setups => lt_program_setups);

    /*******************************************************************************
    * If passed in p_debug_flag IS N, check if debug is enabled in translation table
    *******************************************************************************/

    IF (p_debug_flag != 'Y' AND lt_program_setups('enable_debug') = 'Y')
    THEN

      lc_action := 'Calling set_debug';

      set_debug(p_debug_flag => lt_program_setups('enable_debug'));
    END IF;

    /******************************
    *  Loop thru eligible contracts
    ******************************/

    lc_action := 'Calling c_eligible_contracts cursor';

    FOR eligible_contract_rec IN c_eligible_contracts
    LOOP

      BEGIN

        lb_header_processed := FALSE;

        /************************************************************************
        * Keep track of the contract number and billing sequence being worked on.
        ************************************************************************/

        lc_transaction := 'Processing contract_id: ' || eligible_contract_rec.contract_id;

        logit(p_message => 'Transaction: ' || lc_transaction);

        /******************************
        *  Loop thru eligible contracts
        ******************************/

        lc_action := 'Calling c_eligible_contract_lines cursor';

        FOR eligible_contract_line_rec IN c_eligible_contract_lines(p_contract_id            => eligible_contract_rec.contract_id,
                                                                    p_contract_number        => eligible_contract_rec.contract_number,
                                                                    p_contract_major_version => eligible_contract_rec.contract_major_version)
        LOOP

          lc_transaction_detail := 'contract_line_number: ' || eligible_contract_line_rec.contract_line_number;

          lc_transaction        := lc_transaction || ' ' || lc_transaction_detail;

          logit(p_message => 'Transaction: ' || lc_transaction);

          IF lb_header_processed = FALSE
          THEN
            lb_header_processed := TRUE;

            lc_action := 'Update xx_ar_contracts';
            
            IF eligible_contract_line_rec.cc_trans_id IS NOT NULL
            THEN
              UPDATE xx_ar_contracts
              SET    contract_id                 = eligible_contract_line_rec.contract_id,
                     contract_number             = eligible_contract_line_rec.contract_number,
                     contract_name               = eligible_contract_line_rec.contract_name,
                     contract_status             = eligible_contract_line_rec.contract_status,
                     contract_major_version      = eligible_contract_line_rec.contract_major_version,
                     contract_start_date         = eligible_contract_line_rec.contract_start_date,
                     contract_end_date           = eligible_contract_line_rec.contract_end_date,
                     contract_billing_freq       = eligible_contract_line_rec.contract_billing_freq,
                     bill_to_cust_account_number = eligible_contract_line_rec.bill_cust_account_number,
                     bill_to_customer_name       = eligible_contract_line_rec.bill_cust_name,
                     bill_to_osr                 = eligible_contract_line_rec.bill_to_osr,
                     customer_email              = eligible_contract_line_rec.customer_email,
                     initial_order_number        = eligible_contract_line_rec.initial_order_number,
                     store_number                = LPAD(NVL(eligible_contract_line_rec.store_number, lt_program_setups('default_store_name')),
                                                      6,
                                                      '0'),
                     payment_type                = eligible_contract_line_rec.payment_type,
                     card_type                   = eligible_contract_line_rec.card_type,
                     card_tokenenized_flag       = eligible_contract_line_rec.card_tokenized_flag,
                     card_token                  = eligible_contract_line_rec.card_token,
                     card_encryption_hash        = eligible_contract_line_rec.card_encryption_hash,
                     card_holder_name            = eligible_contract_line_rec.card_holder_name,
                     card_expiration_date        = eligible_contract_line_rec.card_expiration_date,
                     card_encryption_label       = eligible_contract_line_rec.card_encryption_label,
                     ref_associate_number        = eligible_contract_line_rec.ref_associate_number,
                     sales_representative        = eligible_contract_line_rec.sales_representative,
                     loyalty_member_number       = eligible_contract_line_rec.loyalty_member_number,
                     total_contract_amount       = eligible_contract_rec.total_contract_amount,
                     payment_term                = eligible_contract_line_rec.payment_term,
                     payment_identifier          = eligible_contract_line_rec.payment_identifier,
                     payment_last_update_date    = eligible_contract_line_rec.payment_last_update_date,
                     contract_user_status        = eligible_contract_line_rec.contract_user_status,
                     external_source             = eligible_contract_line_rec.external_source,
                     contract_number_modifier    = eligible_contract_line_rec.contract_number_modifier,
                     cc_trans_id                 = eligible_contract_line_rec.cc_trans_id,
                     last_update_date            = SYSDATE,
                     last_updated_by             = FND_GLOBAL.USER_ID,
                     last_update_login           = FND_GLOBAL.USER_ID,
                     program_id                  = NVL(FND_GLOBAL.CONC_PROGRAM_ID,-1) --NVL(FND_GLOBAL.CONC_REQUEST_ID, -1)
              WHERE  contract_id                 = eligible_contract_line_rec.contract_id
              AND    contract_number             = eligible_contract_line_rec.contract_number;
            ELSE
              UPDATE xx_ar_contracts
              SET    contract_id                 = eligible_contract_line_rec.contract_id,
                     contract_number             = eligible_contract_line_rec.contract_number,
                     contract_name               = eligible_contract_line_rec.contract_name,
                     contract_status             = eligible_contract_line_rec.contract_status,
                     contract_major_version      = eligible_contract_line_rec.contract_major_version,
                     contract_start_date         = eligible_contract_line_rec.contract_start_date,
                     contract_end_date           = eligible_contract_line_rec.contract_end_date,
                     contract_billing_freq       = eligible_contract_line_rec.contract_billing_freq,
                     bill_to_cust_account_number = eligible_contract_line_rec.bill_cust_account_number,
                     bill_to_customer_name       = eligible_contract_line_rec.bill_cust_name,
                     bill_to_osr                 = eligible_contract_line_rec.bill_to_osr,
                     customer_email              = eligible_contract_line_rec.customer_email,
                     initial_order_number        = eligible_contract_line_rec.initial_order_number,
                     store_number                = LPAD(NVL(eligible_contract_line_rec.store_number, lt_program_setups('default_store_name')),
                                                      6,
                                                      '0'),
                     payment_type                = eligible_contract_line_rec.payment_type,
                     card_type                   = eligible_contract_line_rec.card_type,
                     card_tokenenized_flag       = eligible_contract_line_rec.card_tokenized_flag,
                     card_token                  = eligible_contract_line_rec.card_token,
                     card_encryption_hash        = eligible_contract_line_rec.card_encryption_hash,
                     card_holder_name            = eligible_contract_line_rec.card_holder_name,
                     card_expiration_date        = eligible_contract_line_rec.card_expiration_date,
                     card_encryption_label       = eligible_contract_line_rec.card_encryption_label,
                     ref_associate_number        = eligible_contract_line_rec.ref_associate_number,
                     sales_representative        = eligible_contract_line_rec.sales_representative,
                     loyalty_member_number       = eligible_contract_line_rec.loyalty_member_number,
                     total_contract_amount       = eligible_contract_rec.total_contract_amount,
                     payment_term                = eligible_contract_line_rec.payment_term,
                     payment_identifier          = eligible_contract_line_rec.payment_identifier,
                     payment_last_update_date    = eligible_contract_line_rec.payment_last_update_date,
                     contract_user_status        = eligible_contract_line_rec.contract_user_status,
                     external_source             = eligible_contract_line_rec.external_source,
                     contract_number_modifier    = eligible_contract_line_rec.contract_number_modifier,
                     last_update_date            = SYSDATE,
                     last_updated_by             = FND_GLOBAL.USER_ID,
                     last_update_login           = FND_GLOBAL.USER_ID,
                     program_id                  = NVL(FND_GLOBAL.CONC_PROGRAM_ID,-1) --NVL(FND_GLOBAL.CONC_REQUEST_ID, -1)
              WHERE  contract_id                 = eligible_contract_line_rec.contract_id
              AND    contract_number             = eligible_contract_line_rec.contract_number;
            END IF;

            logit(p_message => lc_action || ' row counts ' || SQL%ROWCOUNT);

            IF SQL%ROWCOUNT = 0
            THEN


              lc_action := 'Building xx_ar_contracts record';

              lr_contract_info                             := NULL;
              lr_contract_info.contract_id                 := eligible_contract_line_rec.contract_id;
              lr_contract_info.contract_number             := eligible_contract_line_rec.contract_number;
              lr_contract_info.contract_name               := eligible_contract_line_rec.contract_name;
              lr_contract_info.contract_status             := eligible_contract_line_rec.contract_status;
              lr_contract_info.contract_major_version      := eligible_contract_line_rec.contract_major_version;
              lr_contract_info.contract_start_date         := eligible_contract_line_rec.contract_start_date;
              lr_contract_info.contract_end_date           := eligible_contract_line_rec.contract_end_date;
              lr_contract_info.contract_billing_freq       := eligible_contract_line_rec.contract_billing_freq;
              lr_contract_info.bill_to_cust_account_number := eligible_contract_line_rec.bill_cust_account_number;
              lr_contract_info.bill_to_customer_name       := eligible_contract_line_rec.bill_cust_name;
              lr_contract_info.bill_to_osr                 := eligible_contract_line_rec.bill_to_osr;
              lr_contract_info.customer_email              := eligible_contract_line_rec.customer_email;
              lr_contract_info.initial_order_number        := eligible_contract_line_rec.initial_order_number;
              lr_contract_info.store_number                := LPAD(NVL(eligible_contract_line_rec.store_number, lt_program_setups('default_store_name')),
                                                                   6,
                                                                   '0');
              lr_contract_info.payment_type                := eligible_contract_line_rec.payment_type;
              lr_contract_info.card_type                   := eligible_contract_line_rec.card_type;
              lr_contract_info.card_tokenenized_flag       := eligible_contract_line_rec.card_tokenized_flag;
              lr_contract_info.card_token                  := eligible_contract_line_rec.card_token;
              lr_contract_info.card_encryption_hash        := eligible_contract_line_rec.card_encryption_hash;
              lr_contract_info.card_holder_name            := eligible_contract_line_rec.card_holder_name;
              lr_contract_info.card_expiration_date        := eligible_contract_line_rec.card_expiration_date;
              lr_contract_info.card_encryption_label       := eligible_contract_line_rec.card_encryption_label;
              lr_contract_info.ref_associate_number        := eligible_contract_line_rec.ref_associate_number;
              lr_contract_info.sales_representative        := eligible_contract_line_rec.sales_representative;
              lr_contract_info.loyalty_member_number       := eligible_contract_line_rec.loyalty_member_number;
              lr_contract_info.total_contract_amount       := eligible_contract_rec.total_contract_amount;
              lr_contract_info.payment_term                := eligible_contract_line_rec.payment_term;
              lr_contract_info.payment_identifier          := eligible_contract_line_rec.payment_identifier;
              lr_contract_info.payment_last_update_date    := eligible_contract_line_rec.payment_last_update_date;
              lr_contract_info.contract_user_status        := eligible_contract_line_rec.contract_user_status;
              lr_contract_info.external_source             := eligible_contract_line_rec.external_source;
              lr_contract_info.contract_number_modifier    := eligible_contract_line_rec.contract_number_modifier;
              lr_contract_info.last_update_date            := SYSDATE;
              lr_contract_info.last_updated_by             := FND_GLOBAL.USER_ID;
              lr_contract_info.last_update_login           := FND_GLOBAL.USER_ID;
              lr_contract_info.program_id                  := NVL(FND_GLOBAL.CONC_PROGRAM_ID,-1);--NVL(FND_GLOBAL.CONC_REQUEST_ID, -1);
              lr_contract_info.creation_date               := SYSDATE;
              lr_contract_info.created_by                  := FND_GLOBAL.USER_ID;
              
              IF eligible_contract_line_rec.cc_trans_id IS NOT NULL
              THEN
                lr_contract_info.cc_trans_id  := eligible_contract_line_rec.cc_trans_id;
              END IF;
              
              lr_contract_info.cof_trans_id_scm_flag       := 'N';
              lr_contract_info.store_close_flag            := 'N';
            
            --Begin Added for NAIT-126620 4. In the contracts loader program, if the intial_order_number is 20 characters, then always update the external_source as POS
              IF Length(eligible_contract_line_rec.initial_order_number)=20
              THEN
               lr_contract_info.external_source := 'POS';
              END IF;
            --End for NAIT-126620

            --Begin Added for NAIT-127988 Service Subscriptions: Sales Employee Ids with the string "null" for POS Oders
              IF (eligible_contract_line_rec.sales_representative IS NULL OR eligible_contract_line_rec.sales_representative='null')
              THEN
               lr_contract_info.sales_representative :='';
              END IF;
            --End for NAIT-127988

              lc_action := 'Insert into xx_ar_contracts';

              INSERT INTO xx_ar_contracts
              VALUES lr_contract_info;

              logit(p_message => lc_action || ' row counts ' || SQL%ROWCOUNT);

            END IF;

          END IF;

          lc_action := 'Update xx_ar_contract_lines';

          UPDATE xx_ar_contract_lines
          SET    contract_id                = eligible_contract_line_rec.contract_id,
                 contract_number            = eligible_contract_line_rec.contract_number,
                 contract_line_number       = eligible_contract_line_rec.contract_line_number,
                 initial_order_line         = eligible_contract_line_rec.initial_order_line,
                 item_name                  = eligible_contract_line_rec.item_name,
                 item_description           = eligible_contract_line_rec.item_description,
                 quantity                   = eligible_contract_line_rec.quantity,
                 contract_line_start_date   = eligible_contract_line_rec.contract_line_start_date,
                 contract_line_end_date     = eligible_contract_line_rec.contract_line_end_date,
                 contract_line_billing_freq = eligible_contract_line_rec.contract_line_billing_freq,
                 payment_term               = eligible_contract_line_rec.payment_term,
                 uom_code                   = eligible_contract_line_rec.uom_code,
                 contract_line_amount       = eligible_contract_line_rec.total_amount,
                 program                    = eligible_contract_line_rec.program,
                 cancellation_date          = eligible_contract_line_rec.cancellation_date,
                 vendor_number              = eligible_contract_line_rec.vendor_number,
                 initial_billing_sequence   = eligible_contract_line_rec.initial_billing_sequence,
                 purchase_order             = eligible_contract_line_rec.purchase_order,  
                 desktop                    = eligible_contract_line_rec.desktop,
                 cost_center                = eligible_contract_line_rec.cost_center,
                 release_num                = eligible_contract_line_rec.release_num,
                 close_date                 = eligible_contract_line_rec.close_date,
                 last_update_date           = SYSDATE,
                 last_updated_by            = NVL(FND_GLOBAL.USER_ID, -1),
                 last_update_login          = NVL(FND_GLOBAL.USER_ID, -1),
                 program_id                 = NVL(FND_GLOBAL.CONC_PROGRAM_ID,-1),--NVL(FND_GLOBAL.CONC_REQUEST_ID, -1)
                --Begin :  Added for NAIT-127633
                 renewal_type               = eligible_contract_line_rec.renewal_type,
                 renewed_from               = eligible_contract_line_rec.renewed_from,
                 alternative_sku            = eligible_contract_line_rec.alternative_sku,
                 isdiscontinued_flag        = eligible_contract_line_rec.isdiscontinued_flag
                --End 
          WHERE  contract_id                = eligible_contract_line_rec.contract_id
          AND    contract_line_number       = eligible_contract_line_rec.contract_line_number;


          logit(p_message => lc_action || ' row counts ' || SQL%ROWCOUNT);

          IF SQL%ROWCOUNT = 0
          THEN

            lc_action := 'Building xx_ar_contract_lines record';

            lr_contract_line_info                            := NULL;
            lr_contract_line_info.contract_id                := eligible_contract_line_rec.contract_id;
            lr_contract_line_info.contract_number            := eligible_contract_line_rec.contract_number;
            lr_contract_line_info.contract_line_number       := eligible_contract_line_rec.contract_line_number;
            lr_contract_line_info.initial_order_line         := eligible_contract_line_rec.initial_order_line;
            lr_contract_line_info.item_name                  := eligible_contract_line_rec.item_name;
            lr_contract_line_info.item_description           := eligible_contract_line_rec.item_description;
            lr_contract_line_info.quantity                   := eligible_contract_line_rec.quantity;
            lr_contract_line_info.contract_line_start_date   := eligible_contract_line_rec.contract_line_start_date;
            lr_contract_line_info.contract_line_end_date     := eligible_contract_line_rec.contract_line_end_date;
            lr_contract_line_info.contract_line_billing_freq := eligible_contract_line_rec.contract_line_billing_freq;
            lr_contract_line_info.payment_term               := eligible_contract_line_rec.payment_term;
            lr_contract_line_info.uom_code                   := eligible_contract_line_rec.uom_code;
            lr_contract_line_info.contract_line_amount       := eligible_contract_line_rec.total_amount;
            lr_contract_line_info.program                    := eligible_contract_line_rec.program;
            lr_contract_line_info.cancellation_date          := eligible_contract_line_rec.cancellation_date;
            lr_contract_line_info.vendor_number              := eligible_contract_line_rec.vendor_number;
            lr_contract_line_info.initial_billing_sequence   := eligible_contract_line_rec.initial_billing_sequence;
            lr_contract_line_info.purchase_order             := eligible_contract_line_rec.purchase_order;
            lr_contract_line_info.desktop                    := eligible_contract_line_rec.desktop;
            lr_contract_line_info.cost_center                := eligible_contract_line_rec.cost_center;
            lr_contract_line_info.release_num                := eligible_contract_line_rec.release_num;
            lr_contract_line_info.close_date                 := eligible_contract_line_rec.close_date;
            lr_contract_line_info.last_update_date           := SYSDATE;
            lr_contract_line_info.last_updated_by            := NVL(FND_GLOBAL.USER_ID, -1);
            lr_contract_line_info.last_update_login          := NVL(FND_GLOBAL.USER_ID, -1);
            lr_contract_line_info.program_id                 := NVL(FND_GLOBAL.CONC_PROGRAM_ID,-1);--NVL(FND_GLOBAL.CONC_REQUEST_ID, -1);
            lr_contract_line_info.creation_date              := SYSDATE;
            lr_contract_line_info.created_by                 := NVL(FND_GLOBAL.USER_ID , -1);
           --Begin :  Added for NAIT-127633 
            lr_contract_line_info.renewal_type               := eligible_contract_line_rec.renewal_type;
            lr_contract_line_info.renewed_from               := eligible_contract_line_rec.renewed_from;
            lr_contract_line_info.alternative_sku            := eligible_contract_line_rec.alternative_sku;
            lr_contract_line_info.isdiscontinued_flag        := eligible_contract_line_rec.isdiscontinued_flag;
           --END 
            lc_action := 'Insert into xx_ar_contracts_lines';

            
            INSERT INTO xx_ar_contract_lines
            VALUES lr_contract_line_info;


            logit(p_message => lc_action || ' row counts ' || SQL%ROWCOUNT);

          END IF;

        END LOOP;

        lc_action := 'Delete from xx_ar_contracts_gtt';

        DELETE FROM xx_ar_contracts_gtt
        WHERE  contract_id            = eligible_contract_rec.contract_id
        AND    contract_number        = eligible_contract_rec.contract_number
        AND    contract_major_version = eligible_contract_rec.contract_major_version;

        COMMIT;

        ln_records_passed := ln_records_passed + 1;

      EXCEPTION
      WHEN OTHERS
      THEN

        ROLLBACK;

        retcode := 1;

        errbuff := 'Error encountered. Please check logs';

        logit(p_message => 'ERROR Transaction: ' || lc_transaction || ' Action: ' || lc_action || ' SQLCODE: ' || SQLCODE || ' SQLERRM: ' || SQLERRM,
              p_force   => TRUE);

        ln_records_failed := ln_records_failed + 1;

      END;
    END LOOP;

    logit(p_message => 'Records passed: ' || ln_records_passed);
    logit(p_message => 'Records failed: ' || ln_records_failed);
    logit(p_message => 'Total records: '  || (ln_records_passed + ln_records_failed));

    exiting_sub(p_procedure_name => lc_procedure_name);

  EXCEPTION
  WHEN OTHERS
  THEN
    ROLLBACK;
    retcode := 2;
    errbuff := 'Error encountered. Please check logs';
    logit(p_message => 'ERROR Transaction: ' || lc_transaction || ' Action: ' || lc_action || ' SQLCODE: ' || SQLCODE || ' SQLERRM: ' || SQLERRM,
          p_force   => TRUE);
    exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => TRUE);

  END import_contract_info;

  /**************************************
  *  Import Recurring Billing Information
  **************************************/

  PROCEDURE import_recurring_billing_info(errbuff      OUT VARCHAR2,
                                          retcode      OUT NUMBER,
                                          p_debug_flag IN  VARCHAR2 DEFAULT 'N'
                                          )
  IS
    CURSOR c_eligible_recurring_bills
    IS
      SELECT   *
      FROM     xx_ar_subscriptions_gtt
      ORDER BY contract_id,
               billing_sequence_number,
               contract_line_number;

    CURSOR c_eligible_contract_lines(p_contract_id            IN xx_ar_contracts_gtt.contract_id%TYPE,
                                     p_contract_number        IN xx_ar_contracts_gtt.contract_number%TYPE,
                                     p_contract_major_version IN xx_ar_contracts_gtt.contract_major_version%TYPE)
    IS
      SELECT *
      FROM   xx_ar_contracts_gtt
      WHERE  contract_id            = p_contract_id
      AND    contract_number        = p_contract_number
      AND    contract_major_version = p_contract_major_version
      ORDER BY creation_date;

    lc_procedure_name           CONSTANT VARCHAR2(61) := gc_package_name || '.' || 'import_recurring_billing_info';

    lt_parameters               gt_input_parameters;

    lt_program_setups           gt_translation_values;

    lr_subscription_info        xx_ar_subscriptions%ROWTYPE;

    lr_contract_info            xx_ar_contracts%ROWTYPE;

    lc_transaction              VARCHAR2(5000);

    lc_action                   VARCHAR2(1000);

    lb_record_exists            BOOLEAN;

    ln_records_passed           NUMBER := 0;

    ln_records_failed           NUMBER := 0;
    
  BEGIN

    lt_parameters('p_debug_flag') := p_debug_flag;

    entering_main(p_procedure_name   => lc_procedure_name,
                  p_rice_identifier  => 'E7044',
                  p_debug_flag       => p_debug_flag,
                  p_parameters       => lt_parameters);

    retcode := 0;

    /******************************
    * Initialize program variables.
    ******************************/

    get_program_setups(x_program_setups => lt_program_setups);


    /*******************************************************************************
    * If passed in p_debug_flag IS N, check if debug is enabled in translation table
    *******************************************************************************/

    IF (p_debug_flag != 'Y' AND lt_program_setups('enable_debug') = 'Y')
    THEN

      lc_action := 'Calling set_debug';

      set_debug(p_debug_flag => lt_program_setups('enable_debug'));
    END IF;
    
    /************************************
    *  Loop thru eligible recurring bills
    ************************************/

    lc_action := 'Calling c_eligible_recurring_bills cursor';

    FOR eligible_recurring_bill_rec IN c_eligible_recurring_bills
    LOOP

      BEGIN

        /************************************************************************
        * Keep track of the contract number and billing sequence being worked on.
        ************************************************************************/

        lc_transaction := 'Processing contract_id/billing_sequence_number/contract_line_number: ' ||
                           eligible_recurring_bill_rec.contract_id || '/' ||
                           eligible_recurring_bill_rec.billing_sequence_number || '/' ||
                           eligible_recurring_bill_rec.contract_line_number;

        logit(p_message => 'Transaction: ' || lc_transaction);

        /*********************
        * Initialize variables
        *********************/

        lr_subscription_info  := NULL;
        lb_record_exists      := TRUE;

        /**************************************
        * Get contract header level information
        **************************************/

        lc_action := 'Calling get_contract_info';

        get_contract_info(p_contract_id => eligible_recurring_bill_rec.contract_id,
                          x_contract_info   => lr_contract_info);

        /**********************************************
        * Get existing subscription record if it exists
        **********************************************/

        BEGIN

          lc_action := 'Getting xx_ar_subscriptions record';

          SELECT *
          INTO   lr_subscription_info
          FROM   xx_ar_subscriptions
          WHERE  contract_id             = eligible_recurring_bill_rec.contract_id
          AND    billing_sequence_number = eligible_recurring_bill_rec.billing_sequence_number
          AND    contract_line_number    = eligible_recurring_bill_rec.contract_line_number;

          lb_record_exists := TRUE;

        EXCEPTION
        WHEN NO_DATA_FOUND
        THEN
          lb_record_exists := FALSE;
        END;

        /************************************
        * If record does not exist, create it
        ************************************/

        IF lb_record_exists = FALSE
        THEN
          lc_action := 'Building xx_ar_subscriptions record';

          lr_subscription_info.subscriptions_id          := XX_AR_SUBSCRIPTIONS_S.NEXTVAL;
          lr_subscription_info.contract_id               := eligible_recurring_bill_rec.contract_id;
          lr_subscription_info.contract_number           := eligible_recurring_bill_rec.contract_number;
          lr_subscription_info.contract_name             := eligible_recurring_bill_rec.contract_name;
          lr_subscription_info.contract_line_number      := eligible_recurring_bill_rec.contract_line_number;
          lr_subscription_info.billing_date              := eligible_recurring_bill_rec.billing_date;
          lr_subscription_info.contract_line_amount      := eligible_recurring_bill_rec.contract_line_amount;
          lr_subscription_info.billing_sequence_number   := eligible_recurring_bill_rec.billing_sequence_number;
          lr_subscription_info.payment_terms             := eligible_recurring_bill_rec.payment_terms;
          lr_subscription_info.uom_code                  := eligible_recurring_bill_rec.uom_code;
          lr_subscription_info.service_period_start_date := eligible_recurring_bill_rec.service_period_start_date;
          lr_subscription_info.service_period_end_date   := eligible_recurring_bill_rec.service_period_end_date;
          lr_subscription_info.next_billing_date         := eligible_recurring_bill_rec.next_billing_date;
          lr_subscription_info.initial_order_number      := lr_contract_info.initial_order_number;
          lr_subscription_info.creation_date             := SYSDATE;
          lr_subscription_info.last_update_date          := SYSDATE;
          lr_subscription_info.created_by                := NVL(FND_GLOBAL.USER_ID, -1);
          lr_subscription_info.last_updated_by           := NVL(FND_GLOBAL.USER_ID, -1);
          lr_subscription_info.last_update_login         := NVL(FND_GLOBAL.USER_ID, -1);
          lr_subscription_info.program_id                := NVL(FND_GLOBAL.CONC_PROGRAM_ID,-1);--NVL(FND_GLOBAL.CONC_REQUEST_ID, -1);

          lr_subscription_info.invoice_interfaced_flag     := 'N';
          lr_subscription_info.email_sent_flag             := 'N';
          lr_subscription_info.history_sent_flag           := 'N';
          lr_subscription_info.ordt_staged_flag            := 'N';
          lr_subscription_info.invoice_created_flag        := 'N';
          lr_subscription_info.receipt_created_flag        := 'N';
          lr_subscription_info.auth_completed_flag         := 'N';
          lr_subscription_info.email_autorenew_sent_flag   := 'N';
          lr_subscription_info.cof_trans_id_flag           := 'N';          

          lc_action := 'Insert into xx_ar_subscriptions';

          INSERT INTO xx_ar_subscriptions
          VALUES lr_subscription_info;

          logit(p_message => lc_action || ' row counts ' || SQL%ROWCOUNT);

        ELSE

          lc_action := 'Building xx_ar_subscriptions record';

          lr_subscription_info.contract_id               := eligible_recurring_bill_rec.contract_id;
          lr_subscription_info.contract_number           := eligible_recurring_bill_rec.contract_number;
          lr_subscription_info.contract_name             := eligible_recurring_bill_rec.contract_name;
          lr_subscription_info.contract_line_number      := eligible_recurring_bill_rec.contract_line_number;
          lr_subscription_info.billing_date              := eligible_recurring_bill_rec.billing_date;
          lr_subscription_info.contract_line_amount      := eligible_recurring_bill_rec.contract_line_amount;
          lr_subscription_info.billing_sequence_number   := eligible_recurring_bill_rec.billing_sequence_number;
          lr_subscription_info.payment_terms             := eligible_recurring_bill_rec.payment_terms;
          lr_subscription_info.uom_code                  := eligible_recurring_bill_rec.uom_code;
          lr_subscription_info.service_period_start_date := eligible_recurring_bill_rec.service_period_start_date;
          lr_subscription_info.service_period_end_date   := eligible_recurring_bill_rec.service_period_end_date;
          lr_subscription_info.next_billing_date         := eligible_recurring_bill_rec.next_billing_date;
          lr_subscription_info.initial_order_number      := lr_contract_info.initial_order_number;
          lr_subscription_info.last_update_date          := SYSDATE;
          lr_subscription_info.last_updated_by           := NVL(FND_GLOBAL.USER_ID, -1);
          lr_subscription_info.last_update_login         := NVL(FND_GLOBAL.USER_ID, -1);
          lr_subscription_info.program_id                := NVL(FND_GLOBAL.CONC_PROGRAM_ID,-1);--NVL(FND_GLOBAL.CONC_REQUEST_ID, -1);

          lc_action := 'Update into xx_ar_subscriptions';

          UPDATE xx_ar_subscriptions
          SET    ROW = lr_subscription_info
          WHERE  contract_id             = eligible_recurring_bill_rec.contract_id
          AND    billing_sequence_number = eligible_recurring_bill_rec.billing_sequence_number
          AND    contract_line_number    = eligible_recurring_bill_rec.contract_line_number;

          logit(p_message => lc_action || ' row counts ' || SQL%ROWCOUNT);

        END IF;

        DELETE FROM xx_ar_subscriptions_gtt
        WHERE  contract_id             = eligible_recurring_bill_rec.contract_id
        AND    billing_sequence_number = eligible_recurring_bill_rec.billing_sequence_number
        AND    contract_line_number    = eligible_recurring_bill_rec.contract_line_number;

        COMMIT;

        ln_records_passed := ln_records_passed + 1;

      EXCEPTION
      WHEN OTHERS
      THEN

        ROLLBACK;

        retcode := 1;

        errbuff := 'Error encountered. Please check logs';

        ln_records_failed := ln_records_failed + 1;

        logit(p_message => 'ERROR Transaction: ' || lc_transaction || ' Action: ' || lc_action || ' SQLCODE: ' || SQLCODE || ' SQLERRM: ' || SQLERRM,
              p_force   => TRUE);
      END;
    END LOOP;

    logit(p_message => 'Records passed: ' || ln_records_passed);
    logit(p_message => 'Records failed: ' || ln_records_failed);
    logit(p_message => 'Total records: '  || (ln_records_passed + ln_records_failed));

    exiting_sub(p_procedure_name => lc_procedure_name);

  EXCEPTION
  WHEN OTHERS
  THEN

    ROLLBACK;

    retcode := 2;

    errbuff := 'Error encountered. Please check logs';

    logit(p_message => 'ERROR Transaction: ' || lc_transaction || ' Action: ' || lc_action || ' SQLCODE: ' || SQLCODE || ' SQLERRM: ' || SQLERRM,
          p_force   => TRUE);

    exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => TRUE);

  END import_recurring_billing_info;
  
  /*****************************************************
  * Procedure for submitting Auto Invoice Master Program
  ******************************************************/
  
  PROCEDURE process_auto_invoice(errbuff      OUT  VARCHAR2,
                                 retcode      OUT  VARCHAR2,
                                 p_debug_flag IN   VARCHAR2 DEFAULT 'N')
  IS

    lr_trx_source              xx_fin_translatevalues.target_value1%TYPE;
    
    lr_trx_type                xx_fin_translatevalues.target_value1%TYPE;
                             
    lr_operating_unit_info     hr_operating_units%ROWTYPE;
                             
    lr_batch_source_id         ra_batch_sources_all.batch_source_id%TYPE;
                             
    lr_cust_trx_type           ra_cust_trx_types_all%ROWTYPE;
                             
    lc_action                  VARCHAR2(1000);
                             
    ln_autoinv_req_id          NUMBER;
    
    lv_autoinv_complete_flag   BOOLEAN;
    
    lv_phase_txt               VARCHAR2(20);
                         
    lv_status_txt              VARCHAR2(20);
                         
    lv_dev_phase_txt           VARCHAR2(20);
                         
    lv_dev_status_txt          VARCHAR2(20);
                         
    lv_message_txt             VARCHAR2(200);
    
    lt_translation_info        xx_fin_translatevalues%ROWTYPE;
    
    lt_parameters               gt_input_parameters;
    
    lc_procedure_name          CONSTANT VARCHAR2(61) := gc_package_name || '.' || 'process_auto_invoice';
  
  BEGIN
  
    lt_parameters('p_debug_flag') := p_debug_flag;
    
    entering_main(p_procedure_name   => lc_procedure_name,
                  p_rice_identifier  => 'E7044',
                  p_debug_flag       => p_debug_flag,
                  p_parameters       => lt_parameters);
   
    retcode := 0;
   
    /***********************
    * Get transaction source
    ***********************/
   
    lc_action :=  'Calling get_translation_info for transaction source';
   
    lt_translation_info := NULL;
   
    lt_translation_info.source_value1 := 'TRANSACTION_SOURCE';
   
    get_translation_info(p_translation_name  => 'XX_AR_SUBSCRIPTIONS',
                         px_translation_info => lt_translation_info);
   
    lr_trx_source := lt_translation_info.target_value1;
    
    /*********************
    * Get transaction type
    *********************/
   
    lc_action :=  'Calling get_translation_info for transaction type';
   
    lt_translation_info := NULL;
   
    lt_translation_info.source_value1 := 'TRANSACTION_TYPE';
   
    get_translation_info(p_translation_name  => 'XX_AR_SUBSCRIPTIONS',
                         px_translation_info => lt_translation_info);
   
    lr_trx_type := lt_translation_info.target_value1;
   
    /****************************************
    * get organization_id and set_of_books_id
    ****************************************/
    IF lr_operating_unit_info.organization_id IS NULL
    THEN
      lc_action := 'Calling get_operating_unit_info';
   
      get_operating_unit_info(p_ord_id               => FND_PROFILE.VALUE('ORG_ID'),
                              x_operating_unit_info  => lr_operating_unit_info);
    END IF;
    
    /***********************
    * get transaction source
    ***********************/
   
    lc_action := 'Calling get_batch_source_info';
   
    get_batch_source_info(p_trx_source       => lr_trx_source,
                          p_ord_id           => lr_operating_unit_info.organization_id,
                          x_batch_source_id  => lr_batch_source_id);
   
    /**************************
    * get cust transaction type
    **************************/
   
    lc_action := 'Calling get_cust_trx_type_info';
   
    get_cust_trx_type_info(p_trx_type       => lr_trx_type,
                           x_cust_trx_type  => lr_cust_trx_type); 
    
    lc_action := 'Submitting Auto Invoice Master Program';
    
    ln_autoinv_req_id := fnd_request.submit_request(application   =>       'AR',
                                                    program       =>       'RAXMTR',
                                                    description   =>       'Autoinvoice Master Program',
                                                    start_time    =>        SYSDATE,
                                                    argument1     =>        1,
                                                    argument2     =>        lr_operating_unit_info.organization_id,
                                                    argument3     =>        lr_batch_source_id,
                                                    argument4     =>        lr_trx_source,
                                                    argument5     =>        TO_CHAR(TRUNC(SYSDATE), 'RRRR/MM/DD HH24:MI:SS'),
                                                    argument6     =>        '',
                                                    argument7     =>        lr_cust_trx_type.cust_trx_type_id,
                                                    argument8     =>        '',
                                                    argument9     =>        '',
                                                    argument10    =>        '',
                                                    argument11    =>        '',
                                                    argument12    =>        '',
                                                    argument13    =>        '',
                                                    argument14    =>        '',
                                                    argument15    =>        '',
                                                    argument16    =>        '',
                                                    argument17    =>        '',
                                                    argument18    =>        '',
                                                    argument19    =>        '',
                                                    argument20    =>        '',
                                                    argument21    =>        '',
                                                    argument22    =>        '',
                                                    argument23    =>        '',
                                                    argument24    =>        '',
                                                    argument25    =>        '',
                                                    argument26    =>        'Y',
                                                    argument27    =>        '',
                                                    argument28    =>        CHR(0) );
    COMMIT;
   
    IF ln_autoinv_req_id = 0
    THEN
      logit(p_message =>'Conc. Program  failed to submit Auto Invoice');
      retcode := 2;
    ELSE
      lc_action := 'Waiting for concurrent request to complete';
      lv_autoinv_complete_flag := fnd_concurrent.wait_for_request(request_id  =>  ln_autoinv_req_id,
                                                                 phase       =>  lv_phase_txt,
                                                                 status      =>  lv_status_txt,
                                                                 dev_phase   =>  lv_dev_phase_txt,
                                                                 dev_status  =>  lv_dev_status_txt,
                                                                 MESSAGE     =>  lv_message_txt);
   
      IF UPPER(lv_dev_status_txt) = 'NORMAL' AND UPPER(lv_dev_phase_txt) = 'COMPLETE'
      THEN
        logit(p_message =>'Auto Invoice program successful for the Request Id: '
                        || ln_autoinv_req_id
                        || ' and Batch Source: '
                        || lr_trx_source);
      ELSE
        logit(p_message =>'Auto Invoice Program did not complete normally. ');
        retcode := 2;
      END IF;
   
    END IF;
    
    exiting_sub(p_procedure_name => lc_procedure_name);
  
  EXCEPTION
    WHEN OTHERS
    THEN
        
      logit(p_message => 'ERROR  Action: ' || lc_action || ' SQLCODE: ' || SQLCODE || ' SQLERRM: ' || SQLERRM,
            p_force   => TRUE);
            
      retcode := 2;   
        
      errbuff := 'Error encountered. Please check logs';
        
      exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => TRUE);
  END process_auto_invoice;
  
  /* ************************************************************************
  * Procedure to get Alt SKU information
  *************************************************************************/
  PROCEDURE get_alt_sku_info(p_item_name      IN         xx_ar_contract_lines.item_name%TYPE,
                             x_alt_sku_info   OUT NOCOPY alt_sku_table)
  IS
  
    lc_procedure_name  CONSTANT VARCHAR2(61) := gc_package_name || '.' || 'get_alt_sku_info';
    lt_parameters      gt_input_parameters;

  BEGIN

    lt_parameters('p_item_name') := p_item_name;

    entering_sub(p_procedure_name  => lc_procedure_name,
                 p_parameters      => lt_parameters);
    
    SELECT *
           BULK COLLECT
    INTO   x_alt_sku_info
    FROM   xx_od_oks_alt_sku_tbl
    WHERE  org_sku = p_item_name;

    logit(p_message => 'RESULT item_number: ' || x_alt_sku_info.count);

    exiting_sub(p_procedure_name => lc_procedure_name);

    EXCEPTION
    WHEN OTHERS
    THEN
      exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => TRUE);
      RAISE_APPLICATION_ERROR(-20101, 'PROCEDURE: ' || lc_procedure_name || ' SQLCODE: ' || SQLCODE || ' SQLERRM: ' || SQLERRM);
  END get_alt_sku_info;
  
  /* *******************************************************
   Procedure to get Alt SKU information based on ALT SKU
  **********************************************************/
  
  PROCEDURE get_alternate_sku_info(p_item_name            IN         xx_ar_contract_lines.item_name%TYPE,
                                   p_alternate_sku        IN         xx_od_oks_alt_sku_tbl.alt_sku%TYPE,
                                   x_alternate_sku_array  OUT NOCOPY xx_od_oks_alt_sku_tbl%ROWTYPE)
  IS
    lc_procedure_name  CONSTANT VARCHAR2(61) := gc_package_name || '.' || 'get_alternate_sku_info';
    lt_parameters      gt_input_parameters;
  BEGIN

    lt_parameters('p_item_name')     := p_item_name;
    lt_parameters('p_alternate_sku') := p_alternate_sku;

    entering_sub(p_procedure_name  => lc_procedure_name,
                 p_parameters      => lt_parameters);

    SELECT * 
      INTO x_alternate_sku_array
      FROM xx_od_oks_alt_sku_tbl
     WHERE 1       =  1
       AND org_sku =  p_item_name
       AND alt_sku =  p_alternate_sku;

    exiting_sub(p_procedure_name => lc_procedure_name);

    EXCEPTION
    WHEN OTHERS
    THEN
      exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => TRUE);
      RAISE_APPLICATION_ERROR(-20101, 'PROCEDURE: ' || lc_procedure_name || ' SQLCODE: ' || SQLCODE || ' SQLERRM: ' || SQLERRM);

  END get_alternate_sku_info;  
  
 /* ********************************************
  * Procedure to set DNR at contract line
  **********************************************/
  
  PROCEDURE set_dnr_contract_line
  IS 
      
--Cursor Query to Get Eligible Records for DNR ,isDiscontinued and Alt SKU
    CURSOR c_dnr_contract_det 
     IS
      SELECT contract_id
     FROM
     (
         SELECT XACL.contract_id
         FROM   xx_ar_contract_lines XACL,
                xx_ar_contracts XAC,
                xx_ar_subscriptions XAS,
                xx_od_oks_alt_sku_tbl xast
         WHERE  TRUNC(sysdate+45) = TRUNC(XACL.contract_line_end_date)
         AND    XACL.contract_id = XAC.contract_id
         AND    XAC.contract_status = 'ACTIVE'
         AND    XAC.contract_id = XAS.contract_id
         AND    XACL.contract_line_number = XAS.contract_line_number
         AND    XACL.close_date is NULL
         AND    XACL.program = 'SS'
         AND    NVL(XAS.email_autorenew_sent_flag,'N') != 'Y'
         AND    xacl.item_name = xast.org_sku
         AND    xast.code='Discontinued'
         AND    XAS.billing_sequence_number IN (SELECT MAX(XAS1.billing_sequence_number) 
                                                FROM  xx_ar_subscriptions XAS1
                                                WHERE XAS1.contract_id = XAS.contract_id
                                                AND   XAS1.contract_line_number = XAS.contract_line_number
                                                )
         GROUP BY XACL.contract_id                                                
         UNION
         SELECT XACL.contract_id
         FROM   xx_ar_contract_lines XACL,
                xx_ar_contracts XAC,
                xx_ar_subscriptions XAS,
                xx_od_oks_alt_sku_tbl xast
         WHERE  TRUNC(sysdate+45) = TRUNC(XACL.contract_line_end_date)
         AND    XACL.contract_id = XAC.contract_id
         AND    XAC.contract_status = 'ACTIVE'
         AND    XAC.contract_id = XAS.contract_id
         AND    XACL.contract_line_number = XAS.contract_line_number
         AND    XACL.close_date is NULL
         AND    XACL.program ='BS'
         AND    NVL(XAS.email_autorenew_sent_flag,'N') != 'Y'
         AND    xacl.item_name = xast.org_sku
         AND    xast.code='Discontinued'
         AND    XAS.billing_sequence_number IN (SELECT MAX(XAS1.billing_sequence_number)
                                                FROM  xx_ar_subscriptions XAS1
                                                WHERE XAS1.contract_id = XAS.contract_id
                                                AND   XAS1.contract_line_number = XAS.contract_line_number
                                                )
         GROUP BY XACL.contract_id                                                 
         UNION   
         SELECT XACL.contract_id
         FROM   xx_ar_contract_lines XACL,
                xx_ar_contracts XAC,
                xx_ar_subscriptions XAS,
                xx_od_oks_alt_sku_tbl xast
         WHERE  TRUNC(sysdate+7) = TRUNC(XACL.contract_line_end_date)
         AND    XACL.contract_id = XAC.contract_id
         AND    XAC.contract_status = 'ACTIVE'
         AND    XAC.contract_id = XAS.contract_id
         AND    XACL.contract_line_number = XAS.contract_line_number
         AND    XACL.close_date is NULL
         AND    XACL.program = 'BS'
         AND    NVL(XAS.email_autorenew_sent_flag,'N') != 'Y'
         AND    xacl.item_name = xast.org_sku
         AND    xast.code='Discontinued'
         AND    XAS.billing_sequence_number IN (SELECT MAX(XAS1.billing_sequence_number) 
                                                FROM   xx_ar_subscriptions XAS1
                                                WHERE  XAS1.contract_id = XAS.contract_id
                                                AND    XAS1.contract_line_number = XAS.contract_line_number
                                               )
        GROUP BY XACL.contract_id                                               

     )
     GROUP BY contract_id
     ORDER BY contract_id; 

     CURSOR get_contract_info_dnr (p_cont_id IN xx_ar_contract_lines.contract_id%TYPE) 
         IS
     SELECT contract_id,contract_line_number 
       FROM xx_ar_contract_lines 
      WHERE 1           = 1
        AND contract_id = p_cont_id;

    lc_procedure_name    CONSTANT  VARCHAR2(61) := gc_package_name || '.' || 'set_dnr_contract_line';

    lt_program_setups              gt_translation_values;

    lt_parameters                  gt_input_parameters;

    lc_action                      VARCHAR2(1000);

    lc_error                       VARCHAR2(1000);

    lr_contract_line_info          xx_ar_contract_lines%ROWTYPE;

    lc_wallet_id                   xx_ar_contracts.payment_identifier%TYPE;

    lc_dnr_payload                 VARCHAR2(32000) := NULL;

    l_request                      UTL_HTTP.req;

    l_response                     UTL_HTTP.resp;

    lclob_buffer                   CLOB;

    lc_buffer                      VARCHAR2(10000);

    lr_subscription_payload_info   xx_ar_subscription_payloads%ROWTYPE;

    lr_subscription_error_info     xx_ar_subscriptions_error%ROWTYPE;

    le_processing                  EXCEPTION;
    l_type                         xx_od_oks_alt_sku_tbl.type%TYPE;
    l_code                         xx_od_oks_alt_sku_tbl.code%TYPE;
    l_envelope_head                VARCHAR2(5000) := NULL; 
    l_envelope_line                VARCHAR2(10000) := NULL;  
    l_envelope_line1               VARCHAR2(10000) := NULL; 
    l_alt_sku                      xx_od_oks_alt_sku_tbl.alt_sku%TYPE;
    
    
  BEGIN
  
   /* *****************************
    * Initialize program variables.
    ******************************/

    lc_action := 'Calling get_program_setups in set_dnr_contract_line';
    logit('Calling get_program_setups in set_dnr_contract_line');


    get_program_setups(x_program_setups => lt_program_setups);

    FOR l_dnr_contract_det IN c_dnr_contract_det
    LOOP
    BEGIN
    lc_action := 'Generating DNR header information';
    logit('Generating DNR header information');
  
        /***************************
        * Creating Header Payload
        ****************************/
        l_envelope_head :=      
                 '{
                  "updateContractFieldRequest": 
                   {
                     "transactionHeader": 
                     {
                      "consumer": 
                      {
                       "consumerName": "EBS"
                      }
                     },
                     "contract": 
                      {
                     "contractId": "'|| l_dnr_contract_det.contract_id
                                     || '",
                     "contractLines" : [
                 '; 
        
         lc_action := 'Calling get_contract_line_info in set_dnr_contract_line';
         logit('Calling get_contract_line_info in set_dnr_contract_line');
         
          FOR l_cont_det_dnr IN get_contract_info_dnr(p_cont_id => l_dnr_contract_det.contract_id)
          LOOP  

             /********************************
              * Getting all associates lines
             *********************************/

           get_contract_line_info(p_contract_id          => l_cont_det_dnr.contract_id,
                                  p_contract_line_number => l_cont_det_dnr.contract_line_number,
                                  x_contract_line_info   => lr_contract_line_info);
            
            --Getting the Code and Type based on Line Item from MFT Table
            BEGIN
            SELECT code,type
              INTO l_code,l_type
              FROM xx_od_oks_alt_sku_tbl
             WHERE ORG_SKU = lr_contract_line_info.item_name
             GROUP BY code,type;   
             logit('code and type '||l_code ||' and ' ||l_type);            
            EXCEPTION
             WHEN NO_DATA_FOUND THEN
               l_code := '';
               l_type :='';
               logit('code and type '||l_code ||' and ' ||l_type);
             WHEN OTHERS THEN
               l_code := '';
               l_type :='';
               logit('code and type '||l_code ||' and ' ||l_type);
             END;
 
             logit('Code :-  '||l_code ||' and Type :- ' ||l_type);
            
            lr_contract_line_info.cancellation_date := NVL(lr_contract_line_info.cancellation_date,'31-MAR-20');  
            lr_contract_line_info.renewal_type := NVL(lr_contract_line_info.renewal_type,'X');

            
            IF l_code = 'Discontinued' AND (lr_contract_line_info.cancellation_date ='31-MAR-2020' 
                                            OR lr_contract_line_info.renewal_type <>'DO_NOT_RENEW'
                                            )
             THEN    
             logit('IF condition '||lr_contract_line_info.cancellation_date ||' and ' ||lr_contract_line_info.renewal_type);
             BEGIN

                  IF l_type LIKE 'Forced%' THEN
                  
                    SELECT alt_sku 
                      INTO l_alt_sku 
                      FROM xx_od_oks_alt_sku_tbl
                     WHERE 1       = 1
                       AND ORG_SKU = lr_contract_line_info.item_name
                       AND code    = l_code
                       AND type    = l_type;
                      
                  END IF;

             logit('Alt SKU for Forced Cost: - '||l_alt_sku);
             EXCEPTION
             WHEN NO_DATA_FOUND THEN
               l_alt_sku := NULL;
             WHEN OTHERS THEN
               l_alt_sku := NULL;
             END;
             
             l_envelope_line :=
                '{
                 "lineNumber": "'|| lr_contract_line_info.contract_line_number
                                  || '",
                  "isDiscontinued": "true",
                  "alternativeSku": "'|| l_alt_sku
                                      || '",
                  "autoRenewal": "DO_NOT_RENEW"
                 },';
              l_envelope_line1 := l_envelope_line1||l_envelope_line; 
             
             END IF;
           END LOOP;--FOR l_cont_det_dnr IN get_contract_info_dnr

          l_envelope_line1 := SUBSTR(l_envelope_line1,1,LENGTH(l_envelope_line1)-1)||']}}}';
 
          /* ******************************
             Build auto renew email payload
           *******************************/

          lc_action := 'Building auto DNR payload';
          
          SELECT l_envelope_head||l_envelope_line1
            INTO lc_dnr_payload
            FROM DUAL; 
          
           IF lt_program_setups('wallet_location') IS NOT NULL
           THEN
           
             lc_action := 'calling UTL_HTTP.set_wallet in set_dnr_contract_line';
                        
             UTL_HTTP.SET_WALLET(lt_program_setups('wallet_location'), lt_program_setups('wallet_password'));
           
           END IF;

          lc_action := 'Calling UTL_HTTP.set_response_error_check';

          UTL_HTTP.set_response_error_check(FALSE);

          lc_action := 'Calling UTL_HTTP.begin_request in set_dnr_contract_line';
          
          l_request := UTL_HTTP.begin_request(lt_program_setups('dnr_email_service_url'), 'POST', ' HTTP/1.1');

          lc_action := 'Calling UTL_HTTP.SET_HEADER: user-agent';

          UTL_HTTP.SET_HEADER(l_request, 'user-agent', 'mozilla/4.0');

          lc_action := 'Calling UTL_HTTP.SET_HEADER: content-type';

          UTL_HTTP.SET_HEADER(l_request, 'content-type', 'application/json');

          lc_action := 'Calling UTL_HTTP.SET_HEADER: Content-Length';

          UTL_HTTP.SET_HEADER(l_request, 'Content-Length', LENGTH(lc_dnr_payload));

          lc_action := 'Calling UTL_HTTP.SET_HEADER: Authorization';

          UTL_HTTP.SET_HEADER(l_request, 'Authorization', 'Basic ' || UTL_RAW.cast_to_varchar2(UTL_ENCODE.base64_encode(UTL_RAW.cast_to_raw(lt_program_setups('dnr_email_service_user')
                                                                                                                                            || ':' ||
                                                                                                                                            lt_program_setups('dnr_email_service_pwd')
                                                                                                                                            ))));
          lc_action := 'Calling UTL_HTTP.write_text';

          UTL_HTTP.write_text(l_request, lc_dnr_payload);

          lc_action := 'Calling UTL_HTTP.get_response';

          l_response := UTL_HTTP.get_response(l_request);

          COMMIT;

          logit(p_message => 'Response status_code' || l_response.status_code);

          /*************************
          * Get response into a CLOB
          *************************/

          lc_action := 'Getting response';

          BEGIN
           lclob_buffer := EMPTY_CLOB;
           LOOP
                UTL_HTTP.read_text(l_response, lc_buffer, LENGTH(lc_buffer));
                lclob_buffer := lclob_buffer || lc_buffer;

          END LOOP;
           logit(p_message => 'Response Clob: ' || lclob_buffer);

            UTL_HTTP.end_response(l_response);

           EXCEPTION
             WHEN UTL_HTTP.end_of_body
             THEN
             UTL_HTTP.end_response(l_response);
           END;

            /***********************
            * Store request/response
            ***********************/

            lc_action := 'Store request/response';

            lr_subscription_payload_info.payload_id              := xx_ar_subscription_payloads_s.NEXTVAL;
            lr_subscription_payload_info.response_data           := lclob_buffer;
            lr_subscription_payload_info.creation_date           := SYSDATE;
            lr_subscription_payload_info.created_by              := FND_GLOBAL.USER_ID;
            lr_subscription_payload_info.last_updated_by         := FND_GLOBAL.USER_ID;
            lr_subscription_payload_info.last_update_date        := SYSDATE;
            lr_subscription_payload_info.input_payload           := lc_dnr_payload;
            lr_subscription_payload_info.contract_number         := lr_contract_line_info.contract_number;
            lr_subscription_payload_info.billing_sequence_number := NULL;
            lr_subscription_payload_info.contract_line_number    := lr_contract_line_info.contract_line_number; --NULL;
            lr_subscription_payload_info.source                  := lc_procedure_name;
            lc_action := 'Calling insert_subscription_payload_info in set_dnr_contract_line';

            insert_subscript_payload_info(p_subscription_payload_info => lr_subscription_payload_info);

            IF (l_response.status_code = 200)
            THEN

              lr_contract_line_info.renewal_type  := 'DO_NOT_RENEW';
              --lt_subscription_array(indx).email_autorenew_sent_date  := SYSDATE;
              lr_contract_line_info.last_update_date := SYSDATE;
              lr_contract_line_info.last_updated_by  := FND_GLOBAL.USER_ID;

            ELSE

              lc_action := NULL;

              lc_error  := 'DNR failure - response code: ' || l_response.status_code;

              RAISE le_processing;

            END IF;

            lc_action := ' update_subscription_info in set_dnr_contract_line';

        --update_line_info(p_contract_line_info => lr_contract_line_info);
    EXCEPTION
        WHEN le_processing
        THEN

          lr_subscription_error_info                         := NULL;
          lr_subscription_error_info.contract_id             := lr_contract_line_info.contract_id;
          lr_subscription_error_info.contract_number         := lr_contract_line_info.contract_number;
          lr_subscription_error_info.contract_line_number    := lr_contract_line_info.contract_line_number;
          lr_subscription_error_info.billing_sequence_number := NULL;
          lr_subscription_error_info.error_module            := lc_procedure_name;
          lr_subscription_error_info.error_message           := SUBSTR('Action: ' || lc_action || ' Error: ' || lc_error, 1, gc_max_err_size);
          lr_subscription_error_info.creation_date           := SYSDATE;

          lc_action := 'Calling insert_subscription_error_info in set_dnr_contract_line';

          insert_subscription_error_info(p_subscription_error_info => lr_subscription_error_info);

          lc_error := SUBSTR(lr_subscription_error_info.error_message, 1, gc_max_sub_err_size);

          -- RAISE le_processing;

        WHEN OTHERS
        THEN

          lr_subscription_error_info                         := NULL;
          lr_subscription_error_info.contract_id             := lr_contract_line_info.contract_id;
          lr_subscription_error_info.contract_number         := lr_contract_line_info.contract_number;
          lr_subscription_error_info.contract_line_number    := lr_contract_line_info.contract_line_number;
          lr_subscription_error_info.billing_sequence_number := NULL;
          lr_subscription_error_info.error_module            := lc_procedure_name;
          lr_subscription_error_info.error_message           := SUBSTR('Action: ' || lc_action || ' Error: ' || lc_error, 1, gc_max_err_size);
          lr_subscription_error_info.creation_date           := SYSDATE;

          lc_action := 'Calling insert_subscription_error_info in set_dnr_contract_line';

          insert_subscription_error_info(p_subscription_error_info => lr_subscription_error_info);

          lc_error := SUBSTR(lr_subscription_error_info.error_message, 1, gc_max_sub_err_size);
     END;
     l_alt_sku := '';
     l_envelope_head  :='';
     l_envelope_line := '';
     l_envelope_line1 :='';
     
     END LOOP;--FOR l_dnr_contract_det IN c_dnr_contract_det

 EXCEPTION
      WHEN OTHERS
      THEN

      lr_subscription_error_info                         := NULL;
      lr_subscription_error_info.contract_id             := lr_contract_line_info.contract_id;
      lr_subscription_error_info.contract_number         := lr_contract_line_info.contract_number;
      lr_subscription_error_info.contract_line_number    := lr_contract_line_info.contract_line_number;
      lr_subscription_error_info.billing_sequence_number := NULL;
      lr_subscription_error_info.error_module            := lc_procedure_name;
      lr_subscription_error_info.error_message           := SUBSTR('Action: ' || lc_action || ' Error: ' || lc_error, 1, gc_max_err_size);
      lr_subscription_error_info.creation_date           := SYSDATE;

      lc_action := 'Calling insert_subscription_error_info in set_dnr_contract_line';

      insert_subscription_error_info(p_subscription_error_info => lr_subscription_error_info);

      lc_error := SUBSTR(lr_subscription_error_info.error_message, 1, gc_max_sub_err_size);

      exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => TRUE);
      RAISE_APPLICATION_ERROR(-20101, 'PROCEDURE: ' || lc_procedure_name || ' Action: ' || lc_action || ' SQLCODE: ' || SQLCODE || ' SQLERRM: ' || SQLERRM);
END set_dnr_contract_line;
  
  /* ************************************************************************
  * Helper procedure to send billing email before 45 day contract expiration
  *************************************************************************/
 PROCEDURE send_email_autorenew(errbuff            OUT VARCHAR2,
                                 retcode            OUT NUMBER,
                                 p_debug_flag       IN  VARCHAR2 DEFAULT 'N'
                                )
  IS

   CURSOR c_autorenew_contract_lines 
   IS
     SELECT contract_id,contract_number,billing_sequence_number,notification_days,total_contract_amount,contract_line_number
     FROM
     (
         SELECT XACL.contract_id,XAC.contract_number,XAS.billing_sequence_number,45 notification_days,sum(xacl.contract_line_amount) total_contract_amount
               ,xacl.contract_line_number
         FROM   xx_ar_contract_lines XACL,
                xx_ar_contracts XAC,
                xx_ar_subscriptions XAS
         WHERE  TRUNC(sysdate+45) = TRUNC(XACL.contract_line_end_date)
         AND    XACL.contract_id = XAC.contract_id
         AND    XAC.contract_status = 'ACTIVE'
         AND    XAC.contract_id = XAS.contract_id
         AND    XACL.contract_line_number = XAS.contract_line_number
         AND    XACL.close_date is NULL
         AND    XACL.program = 'SS'
         AND    NVL(XAS.email_autorenew_sent_flag,'N') != 'Y'
         AND    XAS.billing_sequence_number IN (SELECT MAX(XAS1.billing_sequence_number) 
                                                FROM  xx_ar_subscriptions XAS1
                                                WHERE XAS1.contract_id = XAS.contract_id
                                                AND   XAS1.contract_line_number = XAS.contract_line_number
                                                )
         GROUP BY XACL.contract_id,XAC.contract_number,XAS.billing_sequence_number,45,xacl.contract_line_number                                                  
         UNION
         SELECT XACL.contract_id,XAC.contract_number,XAS.billing_sequence_number,45 notification_days,sum(xacl.contract_line_amount) total_contract_amount
               ,xacl.contract_line_number
         FROM   xx_ar_contract_lines XACL,
                xx_ar_contracts XAC,
                xx_ar_subscriptions XAS
         WHERE  TRUNC(sysdate+45) = TRUNC(XACL.contract_line_end_date)
         AND    XACL.contract_id = XAC.contract_id
         AND    XAC.contract_status = 'ACTIVE'
         AND    XAC.contract_id = XAS.contract_id
         AND    XACL.contract_line_number = XAS.contract_line_number
         AND    XACL.close_date is NULL
         AND    XACL.program ='BS'
         AND    NVL(XAS.email_autorenew_sent_flag,'N') != 'Y'
         AND    XAS.billing_sequence_number IN (SELECT MAX(XAS1.billing_sequence_number)
                                                FROM  xx_ar_subscriptions XAS1
                                                WHERE XAS1.contract_id = XAS.contract_id
                                                AND   XAS1.contract_line_number = XAS.contract_line_number
                                                )
         GROUP BY XACL.contract_id,XAC.contract_number,XAS.billing_sequence_number,45,xacl.contract_line_number                                                  
         UNION   
         SELECT XACL.contract_id,XAC.contract_number,XAS.billing_sequence_number,7 notification_days,sum(xacl.contract_line_amount) total_contract_amount
               ,xacl.contract_line_number
         FROM   xx_ar_contract_lines XACL,
                xx_ar_contracts XAC,
                xx_ar_subscriptions XAS
         WHERE  TRUNC(sysdate+7) = TRUNC(XACL.contract_line_end_date)
         AND    XACL.contract_id = XAC.contract_id
         AND    XAC.contract_status = 'ACTIVE'
         AND    XAC.contract_id = XAS.contract_id
         AND    XACL.contract_line_number = XAS.contract_line_number
         AND    XACL.close_date is NULL
         AND    XACL.program = 'BS'
         AND    NVL(XAS.email_autorenew_sent_flag,'N') != 'Y'
         AND    XAS.billing_sequence_number IN (SELECT MAX(XAS1.billing_sequence_number) 
                                                FROM   xx_ar_subscriptions XAS1
                                                WHERE  XAS1.contract_id = XAS.contract_id
                                                AND    XAS1.contract_line_number = XAS.contract_line_number
                                               )
        GROUP BY XACL.contract_id,XAC.contract_number,XAS.billing_sequence_number,7,xacl.contract_line_number                                                

     )
     GROUP BY contract_id,contract_number,billing_sequence_number,notification_days,total_contract_amount,contract_line_number
     ORDER BY contract_id;     

    lc_procedure_name    CONSTANT  VARCHAR2(61) := gc_package_name || '.' || 'send_email_autorenew';

    lt_program_setups              gt_translation_values;

    lt_parameters                  gt_input_parameters;

    lc_action                      VARCHAR2(1000);

    lc_error                       VARCHAR2(1000);

    ln_loop_counter                NUMBER := 0;

    lr_contract_info               xx_ar_contracts%ROWTYPE;

    lr_contract_line_info          xx_ar_contract_lines%ROWTYPE;
    
    lr_alt_sku_info                alt_sku_table;

    lt_subscription_array          subscription_table;

    lc_wallet_id                   xx_ar_contracts.payment_identifier%TYPE;

    lr_invoice_header_info         ra_customer_trx_all%ROWTYPE;

    ln_invoice_total_amount_info   ra_customer_trx_lines_all.extended_amount%TYPE;

    lc_masked_credit_card_number   xx_ar_subscriptions.settlement_cc_mask%TYPE;

    lc_billing_agreement_id        xx_ar_contracts.payment_identifier%TYPE;

    --lc_email_autorenew_payload     VARCHAR2(32000) := NULL;
    lc_email_autorenew_payload     CLOB := NULL;

    lc_card_expiration_date        VARCHAR2(4);

    l_request                      UTL_HTTP.req;

    l_response                     UTL_HTTP.resp;

    lclob_buffer                   CLOB;

    lc_buffer                      VARCHAR2(10000);

    lr_subscription_payload_info   xx_ar_subscription_payloads%ROWTYPE;

    lr_subscription_error_info     xx_ar_subscriptions_error%ROWTYPE;

    lc_email_autorenew_sent_flag   VARCHAR2(2)  := 'N';

    lc_email_sent_counter          NUMBER := 0;

    lc_email_failed_counter        NUMBER := 0;

    le_skip                        EXCEPTION;

    le_processing                  EXCEPTION;
    
    lr_translation_info            xx_fin_translatevalues%ROWTYPE;

    lc_contract_status             xx_ar_subscriptions.contract_status%TYPE;

    lc_next_retry_day              NUMBER;

    lc_day                         NUMBER;

    lc_cancel_date                 DATE;

    lc_reason_code                 VARCHAR2(256) := NULL;

    lv_item_cnt                    NUMBER := 0;
    l_cnt                          NUMBER := 0;
------------------------------------Alt 45 Days Variable---
    l_envelope_head                CLOB := NULL; 
    l_envelope_cur_sku             CLOB := NULL;
    l_envelope_line                CLOB := NULL;  
    l_envelope_line1               CLOB := NULL; 
    l_envelope_bottom              CLOB := NULL;
    lr_cust_profile_info           VARCHAR2(2);
    l_customer_Type1               VARCHAR2(1) := NULL;
    l_type                         xx_od_oks_alt_sku_tbl.type%TYPE;
    l_code                         xx_od_oks_alt_sku_tbl.code%TYPE;

  BEGIN
    
    lt_parameters('p_debug_flag') := p_debug_flag;
    
    entering_main(p_procedure_name   => lc_procedure_name,
                  p_rice_identifier  => 'E7044',
                  p_debug_flag       => p_debug_flag,
                  p_parameters       => lt_parameters);
   
    /* **********************************************************************************************
       Calling procedure for DNR, Discontinued and Alternate SKU validation for Forced SKU
     ************************************************************************************************/
     BEGIN
         set_dnr_contract_line();
      EXCEPTION
     WHEN OTHERS THEN
     logit(p_message => 'Error while dnr processing -' ||SUBSTR('SQLCODE: ' || SQLCODE || ' SQLERRM: ' || SQLERRM, 1, gc_max_sub_err_size));
     END;

   /******************************
    * Initialize program variables.
    ******************************/

    retcode := 0;

    lc_action := 'Calling get_program_setups';

    get_program_setups(x_program_setups => lt_program_setups);

    /******************************
     *Loop thru eligible contracts
     ******************************/

        lc_action := 'Calling c_autorenew_contract_lines';

        FOR autorenew_contract_lines_rec IN c_autorenew_contract_lines
        LOOP

       /**************************************
        * Get contract header level information
        **************************************/

        lc_action := 'Calling get_contract_info in send_email_autorenew';

        get_contract_info(p_contract_id     => autorenew_contract_lines_rec.contract_id,
                          x_contract_info   => lr_contract_info);

        /********************************************
        * Get all the associated subscription records
        ********************************************/

        lt_subscription_array.delete();

        lc_action := 'Calling get_alt_subscription_array in send_email_autorenew';

        get_alt_subscription_array(p_contract_id             => autorenew_contract_lines_rec.contract_id,
                                   p_line_number             => autorenew_contract_lines_rec.contract_line_number,
                                   p_billing_sequence_number => autorenew_contract_lines_rec.billing_sequence_number,
                                   x_subscription_array      => lt_subscription_array);
   
  
        /* *************************************
        * Get BSD customer profile information
        ************************************* */
        BEGIN 
        lc_action := 'Calling get_cust_profile_info in send_email_autorenew';

        lr_cust_profile_info := get_cust_profile_info(p_aops_customer_id    => lr_contract_info.bill_to_osr);

        IF lr_cust_profile_info = 'C'
        THEN 
           l_customer_Type1:='C';
        ELSE 
           l_customer_Type1:= lr_cust_profile_info;
        END IF;
        EXCEPTION
             WHEN NO_DATA_FOUND
             THEN
             l_customer_Type1:='R';
             WHEN OTHERS
             THEN 
             exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => TRUE);
             RAISE_APPLICATION_ERROR(-20101, 'PROCEDURE: ' || lc_procedure_name || ' SQLCODE: ' || SQLCODE || ' SQLERRM: ' || SQLERRM);
         END;

        ln_loop_counter := 0;

      FOR indx IN 1 .. lt_subscription_array.COUNT
      LOOP
       
        BEGIN

          /******************************
          * Get contract line information
          ******************************/
          
          lc_action := 'Calling get_contract_line_info in send_email_autorenew';
          
          get_contract_line_info(p_contract_id          => lt_subscription_array(indx).contract_id,
                                 p_contract_line_number => lt_subscription_array(indx).contract_line_number,
                                 x_contract_line_info   => lr_contract_line_info);

          lr_contract_line_info.cancellation_date := NVL(lr_contract_line_info.cancellation_date,'31-MAR-20');  
          lr_contract_line_info.renewal_type := NVL(lr_contract_line_info.renewal_type,'X'); ----Kayeed Need to add DO_NOT_RENEW to skip the email
        --Begin alt Sku logic
          lr_alt_sku_info.delete();
          BEGIN
             SELECT COUNT(1),code,type 
                    INTO lv_item_cnt, l_code,l_type 
               FROM xx_od_oks_alt_sku_tbl
              WHERE ORG_SKU = lr_contract_line_info.item_name
              GROUP BY code,type;
                
             IF lv_item_cnt > 0 THEN
             
             lc_action := 'Calling get_alt_sku_info in send_email_autorenew';
             
             get_alt_sku_info(p_item_name     => lr_contract_line_info.item_name,
                              x_alt_sku_info  => lr_alt_sku_info);              
             
             END IF;
            EXCEPTION
            WHEN NO_DATA_FOUND
            THEN 
               lv_item_cnt:= 0;
               l_code     := '';
               l_type     := '';
               logit(p_message => 'NO_DATA_FOUND Block of calling get_alt_sku_info in send_email_autorenew -' ||lv_item_cnt);
            WHEN OTHERS
            THEN
               lv_item_cnt:= 0;
               l_code     := '';
               l_type     := '';
               logit(p_message => 'Exception Block of calling get_alt_sku_info in send_email_autorenew -' ||lv_item_cnt);
          END;
       --End alt Sku logic

          IF ln_loop_counter = 0
          THEN
              
            ln_loop_counter := ln_loop_counter + 1;  

            /***************************************
            * Masking card details except for PAYPAL
            ***************************************/
            lc_action := 'Masking credit card in send_email_autorenew';

            IF lr_contract_info.card_type != 'PAYPAL'
            THEN

              IF lt_subscription_array(indx).settlement_cc_mask IS NOT NULL
              THEN

                --lc_masked_credit_card_number :=  LPAD(SUBSTR(lt_subscription_array(indx).settlement_cc_mask, -4), 16, 'x');
                --add below to get only numeric value
                 lc_masked_credit_card_number :=  LPAD(SUBSTR(regexp_replace(lt_subscription_array(indx).settlement_cc_mask,'[^0-9]', ''),-4), 16, 'x');

              ELSE

                lc_masked_credit_card_number := 'BAD CARD'; 

              END IF;

            ELSE

              lc_masked_credit_card_number := NULL;

            END IF;

            /**********************************************************************
            * If paypal, pass billing application id, if masterpass, pass wallet id
            **********************************************************************/

            IF lr_contract_info.card_type = 'PAYPAL'
            THEN

              lc_billing_agreement_id  := lr_contract_info.payment_identifier;

            ELSE

              lc_wallet_id             := lr_contract_info.payment_identifier;

            END IF;

            /***********************
            * Format expiration date
            ***********************/

            IF lr_contract_info.card_expiration_date IS NOT NULL
            THEN

              lc_action := 'Formating card_expiration_date in send_email_autorenew';

              lc_card_expiration_date := TO_CHAR(lr_contract_info.card_expiration_date, 'YYMM'); 

            END IF;
 
            /*******************************
            * Build auto renew email payload
            *******************************/
            logit(p_message => 'Build auto renew email payload');

            lc_action := 'Building auto renew email payload';
           
           IF (lr_contract_line_info.cancellation_date='31-MAR-20'
           and(lr_contract_line_info.renewal_type='X' OR lr_contract_line_info.renewal_type <> 'DO_NOT_RENEW'))
           THEN
          --Payload Header Information
            l_envelope_head:=  
                   '{
                    "billingStatusEmailRequest": {
                    "transactionHeader": {
                    "consumer": {
                                "consumerName": "EBS"
                                },
                            "transactionId": "'
                                    || lt_subscription_array(indx).contract_number
                                    || '-'
                                    || lt_subscription_array(indx).initial_order_number
                                    || '-'
                                    || lt_subscription_array(indx).billing_sequence_number
                                    || '",
                            "timeReceived": null
                    },
                    "customer": {
                            "firstName": "'
                                    || lr_contract_info.bill_to_customer_name
                                    || '",
                            "middleName": null,
                            "lastName": "",
                            "accountNumber": "'
                                    || lr_contract_info.bill_to_osr
                                    || '",
                            "loyaltyNumber": "'
                                    || lr_contract_info.loyalty_member_number
                                    || '",
                            "contact": {
                                "email": "'
                                    || lr_contract_info.customer_email
                                    || '",
                                "phoneNumber": "",
                                "faxNumber": ""
                                }
                                 },
                    "invoice": 
                            {
                            "invoiceNumber": "'
                                    || lt_subscription_array(indx).invoice_number
                                    || '",
                            "orderNumber": "'
                                    || SUBSTR(lt_subscription_array(indx).contract_name,1,9)||SUBSTR(lt_subscription_array(indx).contract_name,11,13)
                                    || '",
                            "contractId": "'
                                    || lt_subscription_array(indx).contract_id
                                    || '",
                            "customerType": "'
                                    || l_customer_Type1
                                    || '",
                            "serviceContractNumber": "'
                                    || lt_subscription_array(indx).contract_number
                                    || '",
                            "contractNumberModifier": "'
                                    || lr_contract_info.contract_number_modifier
                                    || '",
                            "billingSequenceNumber": "'
                                    || lt_subscription_array(indx).billing_sequence_number
                                    || '",
                            "initialBillingSequence": "'
                                    || lr_contract_line_info.initial_billing_sequence
                                    || '",
                            "billingDate": "'
                                    || TO_CHAR(lt_subscription_array(indx).billing_date,'DD-MON-YYYY HH24:MI:SS')
                                    || '",
                            "billingTime": "",
                            "invoiceDate": "",
                            "invoiceTime": "",
                            "autoRenewal" :"Y",
                            "autoRenewalStatus": "SUCCESS",
                            "invoiceStatus": "",
                            "serviceType": "'
                                    || lr_contract_line_info.program
                                    || '", 
                            "notificationDays":"'
                                    || autorenew_contract_lines_rec.notification_days
                                    || '",
                            "contractStatus": "", 
                            "action": "",
                            "nextRetryDate": "",
                            "failureMessage": "",
                            "itemName": "'
                                    || lr_contract_line_info.item_description
                                    || '",
                            "contractNumber": "'
                                    || lt_subscription_array(indx).contract_number
                                    || '",
                            "cancelDate": "",
                            "reasonCode": "",
                            "nextInvoiceDate": "'
                                    ||  TO_CHAR(lt_subscription_array(indx).next_billing_date,'DD-MON-YYYY HH24:MI:SS')
                                    || '",
                            "contractStartDate": "'
                                    || TO_CHAR(lr_contract_info.contract_start_date,'DD-MON-YYYY HH24:MI:SS')
                                    || '",
                            "contractEndDate": "'
                                    || TO_CHAR(lr_contract_info.contract_end_date,'DD-MON-YYYY HH24:MI:SS')
                                    || '",
                            "servicePeriodStartDate": "'
                                    || TO_CHAR(lt_subscription_array(indx).service_period_start_date,'DD-MON-YYYY HH24:MI:SS')
                                    || '",
                            "servicePeriodEndDate": "'
                                    || TO_CHAR(lt_subscription_array(indx).service_period_end_date,'DD-MON-YYYY HH24:MI:SS')
                                    || '",';            
            
            --Case a)Discontinued SKU >> Send Suggested SKUS (Send 45 day 'discontinued with optional alts' renewal notice)
            IF (l_code='Discontinued' 
            and l_type='Optional'            
               )
            THEN
                
                l_envelope_cur_sku :=  
                      '"currentSku":{
                       "itemNumber": "'
                                    || lr_contract_line_info.item_name
                                    || '",
                       "itemName": "'
                                    || lr_contract_line_info.item_description
                                    || '",
                       "itemQunatity":"'
                                    || lr_contract_line_info.quantity
                                    || '",
                       "billingFrequency":"'
                                    || lr_contract_line_info.contract_line_billing_freq
                                    || '",
                       "itemPrice":"'
                                    || lt_subscription_array(indx).contract_line_amount
                                    || '",
                       "discontinuedSku":"true",
                       "itemDescription":" This is service description ",
                        "lineNumber":"'
                                    || lr_contract_line_info.contract_line_number
                                    || '"
                                    },
                     "suggestedSkuList": [';
                      
            FOR indx IN 1 .. lr_alt_sku_info.COUNT
            LOOP
              l_envelope_line :=
                           '{
                         "itemNumber":"'
                                    || lr_alt_sku_info(indx).alt_sku
                                    || '",
                          "itemName":"'
                                    || lr_alt_sku_info(indx).alt_desc
                                    || '",
                          "itemQunatity":"'
                                    || lr_contract_line_info.quantity
                                    || '",
                           "billingFrequency":"'
                                    || lr_alt_sku_info(indx).altfreq
                                    || '",
                           "duration":"'
                                    || lr_alt_sku_info(indx).altterm
                                    || '",
                           "itemPrice":"'
                                    || lr_alt_sku_info(indx).altprice
                                    || '",
                          "forcedSku":"false",
                          "itemDescription":"'
                                    || lr_alt_sku_info(indx).alt_desc
                                    || '"
                           },';
                l_envelope_line1 := l_envelope_line1||l_envelope_line;
                l_cnt  := l_cnt+1;
             END LOOP; 
                
                l_envelope_line1 := SUBSTR(l_envelope_line1,1,LENGTH(l_envelope_line1)-1)||'],';
                
            --Case b)Discontinued SKU >> No suggested SKU (i.e. contract will be terminated email (Send 45 day 'contract will be ending' notice)
            ELSIF (l_code='Discontinued'
               and l_type='No Optional'
                  )
            THEN
                l_envelope_cur_sku :=  
                      '"currentSku":{
                         "itemNumber": "'
                                    || lr_contract_line_info.item_name
                                    || '",
                         "itemName": "'
                                    || lr_contract_line_info.item_description
                                    || '",
                         "itemQunatity":"'
                                    || lr_contract_line_info.quantity
                                    || '",
                         "billingFrequency":"'
                                    || lr_contract_line_info.contract_line_billing_freq
                                    || '",
                         "itemPrice":"'
                                    || lt_subscription_array(indx).contract_line_amount
                                    || '",
                         "discontinuedSku":"true",
                         "type":"No Optional",
                        "itemDescription":" This is service description ",
                         "lineNumber":"'
                                    || lr_contract_line_info.contract_line_number
                                    || '"
                                     },';
                 
                  l_envelope_line1   :='';                                          
          --Case c)Discontinued SKU >> Forced Alternate (Send 45 day 'forced alt' renewal notice)
            ELSIF(l_code='Discontinued' 
              and l_type='Forced Cost'              
                 )
            THEN
                
                l_envelope_cur_sku :=  
                                       
                      '"currentSku":{
                        "itemNumber": "'
                                    || lr_contract_line_info.item_name
                                    || '",
                         "itemName": "'
                                    || lr_contract_line_info.item_description
                                    || '",
                         "itemQunatity":"'
                                    || lr_contract_line_info.quantity
                                    || '",
                         "billingFrequency":"'
                                    || lr_contract_line_info.contract_line_billing_freq
                                    || '",
                         "itemPrice":"'
                                    || lt_subscription_array(indx).contract_line_amount
                                    || '",
                         "discontinuedSku":"true",
                         "itemDescription":" This is service description ",
                         "lineNumber":"'
                                    || lr_contract_line_info.contract_line_number
                                    || '"
                                    },
                     "suggestedSkuList": [';
                                          
            FOR indx IN 1 .. lr_alt_sku_info.COUNT
            LOOP
               l_envelope_line :=
                           '{
                          "itemNumber":"'
                                    || lr_alt_sku_info(indx).alt_sku
                                    || '",
                          "itemName":"'
                                    || lr_alt_sku_info(indx).alt_desc
                                    || '",
                          "itemQunatity":"'
                                    || lr_contract_line_info.quantity
                                    || '",
                          "billingFrequency":"'
                                    || lr_alt_sku_info(indx).altfreq
                                    || '",
                          "duration":"'
                                    || lr_alt_sku_info(indx).altterm
                                    || '",
                          "itemPrice":"'
                                    || lr_alt_sku_info(indx).altprice
                                    || '",
                          "forcedSku":"true",
                           "itemDescription":"'
                                    || lr_alt_sku_info(indx).alt_desc
                                    || '"
                           },';
               l_envelope_line1 := l_envelope_line1||l_envelope_line;
               l_cnt := l_cnt+1;
           END LOOP; 
               l_envelope_line1 := SUBSTR(l_envelope_line1,1,LENGTH(l_envelope_line1)-1)||'],';

           --Case c1)Discontinued SKU >> Forced Alternate (Send 45 day 'forced alt' renewal notice)
            ELSIF(l_code='Discontinued' 
              and l_type='Forced Vendor'              
                 )
             THEN
                l_envelope_cur_sku := 
            
               '"currentSku":{
                         "itemNumber": "'
                                    || lr_contract_line_info.item_name
                                    || '",
                           "itemName": "'
                                    || lr_contract_line_info.item_description
                                    || '",
                       "itemQunatity":"'
                                    || lr_contract_line_info.quantity
                                    || '",
                   "billingFrequency":"'
                                    || lr_contract_line_info.contract_line_billing_freq
                                    || '",
                          "itemPrice":"'
                                    || lt_subscription_array(indx).contract_line_amount
                                    || '",
                    "discontinuedSku":"true",
                    "itemDescription":" This is service description ",
                         "lineNumber":"'
                                    || lr_contract_line_info.contract_line_number
                                    || '"         
                            },';

               l_envelope_line1   :='';
           --Case d)Non-Discontinued/Linked SKU >> Send Suggested SKU (Send 45 day 'optional alts' renewal notice)
            ELSIF (l_code='Linked'
               and l_type='Optional'
                  )
            THEN
                
                l_envelope_cur_sku :=  
                      '"currentSku":{
                         "itemNumber": "'
                                    || lr_contract_line_info.item_name
                                    || '",
                           "itemName": "'
                                    || lr_contract_line_info.item_description
                                    || '",
                       "itemQunatity":"'
                                    || lr_contract_line_info.quantity
                                    || '",
                   "billingFrequency":"'
                                    || lr_contract_line_info.contract_line_billing_freq
                                    || '",
                          "itemPrice":"'
                                    || lt_subscription_array(indx).contract_line_amount
                                    || '",
                    "discontinuedSku":"false",
                    "itemDescription":" This is service description ",
                         "lineNumber":"'
                                    || lr_contract_line_info.contract_line_number
                                    || '"         
                                    },
                   "suggestedSkuList": [';
                                        
            FOR indx IN 1 .. lr_alt_sku_info.COUNT
            LOOP
                
               l_envelope_line :=
                         '{
                         "itemNumber":"'
                                    || lr_alt_sku_info(indx).alt_sku
                                    || '",
                           "itemName":"'
                                    || lr_alt_sku_info(indx).alt_desc
                                    || '",
                       "itemQunatity":"'
                                    || lr_contract_line_info.quantity
                                    || '",
                   "billingFrequency":"'
                                    || lr_alt_sku_info(indx).altfreq
                                    || '",
                           "duration":"'
                                    || lr_alt_sku_info(indx).altterm
                                    || '",
                          "itemPrice":"'
                                    || lr_alt_sku_info(indx).altprice
                                    || '",
                          "forcedSku":"false",
                    "itemDescription":"'
                                    || lr_alt_sku_info(indx).alt_desc
                                    || '"
                          },';
               l_envelope_line1 := l_envelope_line1||l_envelope_line;
               l_cnt  := l_cnt+1;
           END LOOP;     
               l_envelope_line1 := SUBSTR(l_envelope_line1,1,LENGTH(l_envelope_line1)-1)||'],';
 
          --Case e)Current state (Non-Discontinued/Linked SKU >> with no Suggested SKU) 
          --       (Send 45 day 'standard' auto-renewal notice) changes to be made for the existing payload for consistency
           ELSIF (l_code='Linked' 
              and l_type='No Optional'
                 )
           THEN
               l_envelope_cur_sku :=  
                                      
                '"currentSku":{
                         "itemNumber": "'
                                    || lr_contract_line_info.item_name
                                    || '",
                           "itemName": "'
                                    || lr_contract_line_info.item_description
                                    || '",
                       "itemQunatity":"'
                                    || lr_contract_line_info.quantity
                                    || '",
                   "billingFrequency":"'
                                    || lr_contract_line_info.contract_line_billing_freq
                                    || '",
                          "itemPrice":"'
                                    || lt_subscription_array(indx).contract_line_amount
                                    || '",
                    "itemDescription":" This is service description ",
                         "lineNumber":"'
                                    || lr_contract_line_info.contract_line_number
                                    || '"         
                            },';

                 l_envelope_line1   :='';
            
            ELSE
             --Normal Email / Reguler
            l_envelope_cur_sku := 
            
               '"currentSku":{
                         "itemNumber": "'
                                    || lr_contract_line_info.item_name
                                    || '",
                           "itemName": "'
                                    || lr_contract_line_info.item_description
                                    || '",
                       "itemQunatity":"'
                                    || lr_contract_line_info.quantity
                                    || '",
                   "billingFrequency":"'
                                    || lr_contract_line_info.contract_line_billing_freq
                                    || '",
                          "itemPrice":"'
                                    || lt_subscription_array(indx).contract_line_amount
                                    || '",
                    "itemDescription":" This is service description ",
                         "lineNumber":"'
                                    || lr_contract_line_info.contract_line_number
                                    || '"         
                            },';

            l_envelope_line1   :='';
                                    
            END IF; --Alt 45 Day

          --Bottom Payload
            l_envelope_bottom:=
                    '"totals": {
                            "subTotal": "",
                            "tax": "",
                            "delivery": "String",
                            "discount": "String",
                            "misc": "String",
                            "total": ""
                               },
                     "tenders": {
                            "tenderLineNumber": "1",
                            "paymentType": "'
                                    || lr_contract_info.payment_type
                                    || '",
                            "cardType": "'
                                    || lr_contract_info.card_type
                                    || '",
                            "amount": "'
                                    || autorenew_contract_lines_rec.total_contract_amount
                                    || '",
                            "cardnumber": "'
                                    || lc_masked_credit_card_number
                                    || '",
                            "expirationDate": "'
                                    || lc_card_expiration_date
                                    || '",
                            "walletId": "'
                                    || lc_wallet_id
                                    ||'",
                            "billingAgreementId": "'
                                    || lc_billing_agreement_id
                                    || '"
                                }
                    },
                    "storeNumber": "'
                                    || lr_contract_info.store_number 
                                    || '"
                 }
            }';
               
            --Build auto renew email payload Bottom
       
              lc_email_autorenew_payload :=l_envelope_head
                                          ||l_envelope_cur_sku
                                          ||l_envelope_line1
                                          ||l_envelope_bottom;
              
             l_envelope_line1   :='';
             lc_action := 'Validating Wallet location';

            IF lt_program_setups('wallet_location') IS NOT NULL
            THEN

              lc_action := 'calling UTL_HTTP.set_wallet';

              UTL_HTTP.SET_WALLET(lt_program_setups('wallet_location'), lt_program_setups('wallet_password'));

            END IF;

            lc_action := 'Calling UTL_HTTP.set_response_error_check';

            UTL_HTTP.set_response_error_check(FALSE);

            lc_action := 'Calling UTL_HTTP.begin_request';

            l_request := UTL_HTTP.begin_request(lt_program_setups('autorenew_email_service_url'), 'POST', ' HTTP/1.1');

            lc_action := 'Calling UTL_HTTP.SET_HEADER: user-agent';

            UTL_HTTP.SET_HEADER(l_request, 'user-agent', 'mozilla/4.0');

            lc_action := 'Calling UTL_HTTP.SET_HEADER: content-type';

            UTL_HTTP.SET_HEADER(l_request, 'content-type', 'application/json');

            lc_action := 'Calling UTL_HTTP.SET_HEADER: Content-Length';

            UTL_HTTP.SET_HEADER(l_request, 'Content-Length', LENGTH(lc_email_autorenew_payload));

            lc_action := 'Calling UTL_HTTP.SET_HEADER: Authorization';

            UTL_HTTP.SET_HEADER(l_request, 'Authorization', 'Basic ' || UTL_RAW.cast_to_varchar2(UTL_ENCODE.base64_encode(UTL_RAW.cast_to_raw(lt_program_setups('autorenew_email_service_user')
                                                                                                                                              || ':' ||
                                                                                                                                              lt_program_setups('autorenew_email_service_pwd')
                                                                                                                                              ))));
            lc_action := 'Calling UTL_HTTP.write_text';

            UTL_HTTP.write_text(l_request, lc_email_autorenew_payload);

            lc_action := 'Calling UTL_HTTP.get_response';

            l_response := UTL_HTTP.get_response(l_request);

            COMMIT;

            logit(p_message => 'Response status_code' || l_response.status_code);

            /*************************
            * Get response into a CLOB
            *************************/

            lc_action := 'Getting response';

            BEGIN

              lclob_buffer := EMPTY_CLOB;
              LOOP

                UTL_HTTP.read_text(l_response, lc_buffer, LENGTH(lc_buffer));
                lclob_buffer := lclob_buffer || lc_buffer;

              END LOOP;

              logit(p_message => 'Response Clob: ' || lclob_buffer);

              UTL_HTTP.end_response(l_response);

            EXCEPTION
              WHEN UTL_HTTP.end_of_body
              THEN

                UTL_HTTP.end_response(l_response);

            END;

            /***********************
            * Store request/response
            ***********************/

            lc_action := 'Store request/response';

            lr_subscription_payload_info.payload_id              := xx_ar_subscription_payloads_s.NEXTVAL;
            lr_subscription_payload_info.response_data           := lclob_buffer;
            lr_subscription_payload_info.creation_date           := SYSDATE;
            lr_subscription_payload_info.created_by              := FND_GLOBAL.USER_ID;
            lr_subscription_payload_info.last_updated_by         := FND_GLOBAL.USER_ID;
            lr_subscription_payload_info.last_update_date        := SYSDATE;
            lr_subscription_payload_info.input_payload           := lc_email_autorenew_payload;
            lr_subscription_payload_info.contract_number         := lt_subscription_array(indx).contract_number;
            lr_subscription_payload_info.billing_sequence_number := lt_subscription_array(indx).billing_sequence_number;
            lr_subscription_payload_info.contract_line_number    := lt_subscription_array(indx).contract_line_number; --NULL;
            lr_subscription_payload_info.source                  := lc_procedure_name;

            lc_action := 'Calling insert_subscription_payload_info';

            insert_subscript_payload_info(p_subscription_payload_info => lr_subscription_payload_info);

            IF (l_response.status_code = 200)
            THEN

              lc_email_sent_counter := lc_email_sent_counter + 1;
 
              lt_subscription_array(indx).email_autorenew_sent_flag  := 'Y';
              lt_subscription_array(indx).email_autorenew_sent_date  := SYSDATE;
              lt_subscription_array(indx).last_update_date := SYSDATE;
              lt_subscription_array(indx).last_updated_by  := FND_GLOBAL.USER_ID;

            ELSE

              lc_action := NULL;

              lc_error  := 'Email sent failure - response code: ' || l_response.status_code;

              RAISE le_processing;

            END IF;
          END IF;--IF (lr_contract_line_info.cancellation_date='31-MAR-20'

         ELSE
              lt_subscription_array(indx).email_autorenew_sent_flag  := 'Y';
              lt_subscription_array(indx).email_autorenew_sent_date  := SYSDATE;
              lt_subscription_array(indx).last_update_date := SYSDATE;
              lt_subscription_array(indx).last_updated_by  := FND_GLOBAL.USER_ID;

         END IF;--ln_loop_counter end if

         lc_action := 'Calling update_subscription_info';

        update_subscription_info(px_subscription_info => lt_subscription_array(indx));

      EXCEPTION
        WHEN le_processing
        THEN

          lr_subscription_error_info                         := NULL;
          lr_subscription_error_info.contract_id             := lt_subscription_array(indx).contract_id;
          lr_subscription_error_info.contract_number         := lt_subscription_array(indx).contract_number;
          lr_subscription_error_info.contract_line_number    := NULL;
          lr_subscription_error_info.billing_sequence_number := lt_subscription_array(indx).billing_sequence_number;
          lr_subscription_error_info.error_module            := lc_procedure_name;
          lr_subscription_error_info.error_message           := SUBSTR('Action: ' || lc_action || ' Error: ' || lc_error, 1, gc_max_err_size);
          lr_subscription_error_info.creation_date           := SYSDATE;

          lc_action := 'Calling insert_subscription_error_info';
          logit(p_message => 'Calling insert_subscription_error_info le_processing in send_email_autorenew ');

          insert_subscription_error_info(p_subscription_error_info => lr_subscription_error_info);

          lc_email_autorenew_sent_flag := 'E';
          lc_error := SUBSTR(lr_subscription_error_info.error_message, 1, gc_max_sub_err_size);

          --RAISE le_processing;

        WHEN OTHERS
        THEN

          lr_subscription_error_info                         := NULL;
          lr_subscription_error_info.contract_id             := lt_subscription_array(indx).contract_id;
          lr_subscription_error_info.contract_number         := lt_subscription_array(indx).contract_number;
          lr_subscription_error_info.contract_line_number    := NULL;
          lr_subscription_error_info.billing_sequence_number := lt_subscription_array(indx).billing_sequence_number;
          lr_subscription_error_info.error_module            := lc_procedure_name;
          lr_subscription_error_info.error_message           := SUBSTR('Action: ' || lc_action || ' Error: ' || SQLCODE || ' ' || SQLERRM, 1, gc_max_err_size);
          lr_subscription_error_info.creation_date           := SYSDATE;

          lc_action := 'Calling insert_subscription_error_info';
          logit(p_message => 'Calling insert_subscription_error_info OTHERS in send_email_autorenew ');

          insert_subscription_error_info(p_subscription_error_info => lr_subscription_error_info);

          lc_email_autorenew_sent_flag := 'E';
          lc_error := SUBSTR(lr_subscription_error_info.error_message, 1, gc_max_sub_err_size);

          --RAISE le_processing;
      END;
        
       END LOOP; -- indx IN 1 .. lt_subscription_array.COUNT
       l_envelope_head   :='';  
       l_envelope_cur_sku:='';   
       l_envelope_line   :='';       
       l_envelope_line1  :='';     
       l_envelope_bottom :=''; 
   END LOOP; --  autorenew_contract_lines_rec IN c_autorenew_contract_lines

  EXCEPTION
    WHEN OTHERS
    THEN

      FOR indx IN 1 .. lt_subscription_array.COUNT
      LOOP

        lt_subscription_array(indx).email_autorenew_sent_flag    := 'E';
        lt_subscription_array(indx).subscription_error := SUBSTR('Action: ' || lc_action || 'SQLCODE: ' || SQLCODE || ' SQLERRM: ' || SQLERRM, 1, gc_max_sub_err_size);

        lc_action := 'Calling update_subscription_info to update with error info';

        update_subscription_info(px_subscription_info => lt_subscription_array(indx));

      END LOOP;

      exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => TRUE);
      RAISE_APPLICATION_ERROR(-20101, 'PROCEDURE: ' || lc_procedure_name || ' Action: ' || lc_action || ' SQLCODE: ' || SQLCODE || ' SQLERRM: ' || SQLERRM);
  END send_email_autorenew;
  
  /***********************************************
  * Helper procedure to generate billing history
  *********************************************/

  PROCEDURE generate_bill_history_payload(errbuff            OUT VARCHAR2,
                                          retcode            OUT NUMBER,
                                          p_file_path        IN  VARCHAR2,
                                          p_debug_flag       IN  VARCHAR2 DEFAULT 'N',
                                          p_text_value       IN  VARCHAR2)
  IS
  
    CURSOR c_eligible_contracts
    IS
      select distinct xas.contract_id,
                      xas.billing_sequence_number
      from   xx_ar_subscriptions xas
            ,xx_ar_contract_lines xacl
      where  xas.contract_id              = xacl.contract_id
      and    xas.contract_line_number     = xacl.contract_line_number
      and    xas.billing_sequence_number >= xacl.initial_billing_sequence
      and    xas.invoice_created_flag     = 'Y'
      and    xas.invoice_number     is not null
      order by xas.contract_id             asc,
               xas.billing_sequence_number ASC;

    lc_procedure_name    CONSTANT  VARCHAR2(61) := gc_package_name || '.' || 'generate_bill_history_payload';

    lc_masked_credit_card_number  xx_ar_subscriptions.settlement_cc_mask%TYPE;

    lt_parameters                  gt_input_parameters;

    lc_action                      VARCHAR2(1000);

    lc_error                       VARCHAR2(1000);

    ln_loop_counter                NUMBER := 0;
    
    lr_contract_info               xx_ar_contracts%ROWTYPE;

    lt_subscription_array          subscription_table;

    lr_contract_line_info          xx_ar_contract_lines%ROWTYPE;

    lr_invoice_header_info         ra_customer_trx_all%ROWTYPE;

    ln_invoice_total_amount_info   ra_customer_trx_lines_all.extended_amount%TYPE;

    lr_bill_to_cust_location_info  hz_locations%ROWTYPE;

    lc_billing_agreement_id        xx_ar_contracts.payment_identifier%TYPE;

    lc_wallet_id                   xx_ar_contracts.payment_identifier%TYPE;

    lc_card_expiration_date        VARCHAR2(4);

    lc_history_sent_flag           VARCHAR2(2) := 'N';

    lr_subscription_payload_info   xx_ar_subscription_payloads%ROWTYPE;

    lr_subscription_error_info     xx_ar_subscriptions_error%ROWTYPE;

    lc_item_unit_total             xx_ar_subscriptions.total_contract_amount%TYPE;

    le_skip                        EXCEPTION;

    le_processing                  EXCEPTION;

    lc_history_payload             VARCHAR2(32000) := NULL;

    lb_history_hrd_processed       BOOLEAN := FALSE;

    lc_history_payload_lines       VARCHAR2(32000) := NULL;

    lc_history_payload_tender      VARCHAR2(32000) := NULL;

    lr_order_header_info           oe_order_headers_all%ROWTYPE;

    lr_bill_to_cust_acct_site_info hz_cust_acct_sites_all%ROWTYPE;

    l_request                      UTL_HTTP.req;
    
    l_response                     UTL_HTTP.resp;

    lc_buff                        VARCHAR2(32000);
                                   
    lc_clob_buff                   CLOB;

    lc_parentheses                 VARCHAR2(100)   := NULL;

    lc_contract_line               VARCHAR2(32000) := NULL;

    lc_invoice_status              VARCHAR2(25)    := NULL;
    
    lr_pos_ordt_info               xx_ar_order_receipt_dtl%ROWTYPE;
    
    lr_pos_info                    xx_ar_pos_inv_order_ref%ROWTYPE;
    
    lr_customer_info               hz_cust_accounts%ROWTYPE;
    
    lc_failure_message             VARCHAR2(256)   := NULL;
    
    lc_auth_time                   xx_ar_subscriptions.auth_datetime%TYPE;
    
    lc_next_retry_date             DATE;

    lr_termination_sku             xx_fin_translatevalues.target_value1%TYPE;
    
    ln_request_id                  NUMBER;
    
    lc_indx_value                  VARCHAR2(1000);
       
    lr_translation_info            xx_fin_translatevalues%ROWTYPE;
    
    lt_file_handle                 UTL_FILE.file_type;
    
    lt_file_name                   VARCHAR2(100)   := TO_CHAR(NULL);
    
    lt_translation_info            xx_fin_translatevalues%ROWTYPE;
    
    ln_max_linesize                NUMBER          := 32000;
    
  BEGIN
       
    lt_parameters('p_debug_flag') := p_debug_flag;
       
    entering_sub(p_procedure_name  => lc_procedure_name,
                 p_parameters      => lt_parameters);
   
    ln_request_id := fnd_global.conc_request_id;

    lc_indx_value := '{"index":{"_index":';
    
    lt_file_name    := 'XX_SUBSCR_BILLHISTORY'||'_'||TO_CHAR (SYSDATE,'DDMONYYYYHH24MISS')||'.txt';

    logit(p_message =>'VALUE OF lt_file_name is'||lt_file_name);
      
    lt_file_handle := UTL_FILE.fopen (p_file_path,lt_file_name,'W',ln_max_linesize);
       
    
    /********************
    * Get termination_sku
    ********************/
    
    lc_action :=  'Calling get_translation_info for termination sku';
    
    lt_translation_info := NULL;
    
    lt_translation_info.source_value1 := 'TERMINATION_SKU';
    
    get_translation_info(p_translation_name  => 'XX_AR_SUBSCRIPTIONS',
                         px_translation_info => lt_translation_info);
    
    lr_termination_sku := lt_translation_info.target_value1;
          
    /***********************************************
    *  Loop thru pending contracts/billing sequences
    ***********************************************/

    lc_action := 'Calling c_eligible_contracts cursor';

    FOR eligible_contract_rec IN c_eligible_contracts
    LOOP
         
      lb_history_hrd_processed     := FALSE;
                                   
      lc_history_payload           := NULL;
                                   
      lc_history_payload_lines     := NULL;
                                   
      lc_history_payload_tender    := NULL;
                                   
      lc_parentheses               := NULL;
                                   
      lc_contract_line             := NULL;
                                   
      ln_loop_counter              := 0;
      
      lc_masked_credit_card_number := NULL;
      
      lc_billing_agreement_id      := NULL;
      
      lc_wallet_id                 := NULL;
      
      lc_card_expiration_date      := NULL;
      
      lc_item_unit_total           := 0;
      
      lr_contract_info             := NULL;
      
      lr_contract_line_info        := NULL;
      
      lr_invoice_header_info       := NULL;
      
      ln_invoice_total_amount_info := 0;
      
      lr_order_header_info         := NULL;
      
      lr_bill_to_cust_acct_site_info := NULL;
      
      lr_bill_to_cust_location_info  := NULL;
      
      lc_invoice_status              := NULL;
      
      lc_failure_message             := NULL;
      
      lc_auth_time                   := NULL;
            
      lc_next_retry_date             := NULL;
      /**************************************
      * Get contract header level information
      **************************************/
      
      lc_action := 'Calling get_contract_info';
      
      get_contract_info(p_contract_id     => eligible_contract_rec.contract_id,
                        x_contract_info   => lr_contract_info);
      
      /********************************************
      * Get all the associated subscription records
      ********************************************/
      
      lt_subscription_array.delete();
      
      lc_action := 'Calling get_subscription_array';
      
      get_subscription_array(p_contract_id             => eligible_contract_rec.contract_id,
                             p_billing_sequence_number => eligible_contract_rec.billing_sequence_number,
                             x_subscription_array      => lt_subscription_array);
                             
      /*******************************************************************
      * Loop thru all the information in subscriptions for sending history
      *******************************************************************/
      
      lc_action := 'Looping thru subscription array for history service - header information';
      
      FOR indx IN 1 .. lt_subscription_array.COUNT
      LOOP
       
       
        BEGIN
          
          /************************************
          * Get contract line level information
          ************************************/
          
          lc_action := 'Calling get_contract_line_info generate_bill_history_payload';
          
          get_contract_line_info(p_contract_id          => lt_subscription_array(indx).contract_id,
                                 p_contract_line_number => lt_subscription_array(indx).contract_line_number,
                                 x_contract_line_info   => lr_contract_line_info);
    
          IF lr_contract_line_info.item_name = lr_termination_sku
          THEN 
            lc_error := 'Termination SKU : ' || lr_contract_line_info.item_name;
            RAISE le_skip;
          END IF;
        
          IF lt_subscription_array(indx).billing_sequence_number >= lr_contract_line_info.initial_billing_sequence
          THEN
      
            IF lb_history_hrd_processed != TRUE
            THEN
      
              /************************
              * Get invoice information
              ************************/
      
              lc_action := 'Calling get_invoice_header_info';
      
              get_invoice_header_info(p_invoice_number      => lt_subscription_array(indx).invoice_number,
                                      x_invoice_header_info => lr_invoice_header_info);
              
              /******************************
              * Get invoice total information
              ******************************/
              
              lc_action := 'Calling get_invoice_total_amount_info';
      
              get_invoice_total_amount_info(p_customer_trx_id           => lr_invoice_header_info.customer_trx_id,
                                            x_invoice_total_amount_info => ln_invoice_total_amount_info);
               
              /******************************
              * Get initial order header info
              ******************************/
              
              lc_action := 'Calling get_order_header_info';
      
              IF lr_contract_info.external_source = 'POS'
              THEN
                get_pos_ordt_info(p_order_number => lr_contract_info.initial_order_number,
                      x_ordt_info    => lr_pos_ordt_info);
                      
                get_pos_info(p_header_id        => lr_pos_ordt_info.header_id,
                             p_orig_sys_doc_ref => lr_contract_info.initial_order_number,
                             x_pos_info         => lr_pos_info);
                             
                get_order_header_info(--p_order_number      => lr_pos_info.sales_order,            --Commented for NAIT-126620.   
                                      p_order_number      => lr_contract_info.initial_order_number, --Added for NAIT-126620
                                      x_order_header_info => lr_order_header_info);
              ELSE
                get_order_header_info(p_order_number      => lr_contract_info.initial_order_number,
                                      x_order_header_info => lr_order_header_info);
              END IF;
              
              /*************************************************
              * Get initial order BILL_TO cust account site info
              *************************************************/
              
              lc_action := 'Calling get_cust_account_site_info for BILL_TO';
      
              IF lr_contract_info.external_source = 'POS'
              THEN
                get_customer_pos_info(p_aops           => lr_contract_info.bill_to_osr,
                                      x_customer_info  => lr_customer_info);
                                    
                get_cust_site_pos_info(p_customer_id     => lr_customer_info.cust_account_id,
                                       x_cust_site_info  => lr_bill_to_cust_acct_site_info);
              ELSE
                get_cust_account_site_info(p_site_use_id            => lr_order_header_info.invoice_to_org_id,
                                           p_site_use_code          => 'BILL_TO',
                                           x_cust_account_site_info => lr_bill_to_cust_acct_site_info);
              END IF;
              
              /***********************************
              * Get initial order BILL_TO location
              ***********************************/
              
              lc_action := 'Calling get_cust_location_info for BILL_TO';
      
              get_cust_location_info(p_cust_acct_site_id  => lr_bill_to_cust_acct_site_info.cust_acct_site_id,
                                     x_cust_location_info => lr_bill_to_cust_location_info);
              
              /*********************
              * Masking card details
              *********************/
      
              lc_action := 'Masking credit card';
      
              lc_masked_credit_card_number := LPAD(SUBSTR(lt_subscription_array(indx).settlement_cc_mask, -4), 16, 'x');
      
              /**********************************************************************
              * If paypal, pass billing application id, if masterpass, pass wallet id
              **********************************************************************/
      
              IF lr_contract_info.card_type = 'PAYPAL'
              THEN
      
                lc_billing_agreement_id := lr_contract_info.payment_identifier;
      
              ELSE
      
                lc_wallet_id := lr_contract_info.payment_identifier;
      
              END IF;
      
              /***********************
              * Format expiration date
              ***********************/
      
              IF lr_contract_info.card_expiration_date IS NOT NULL
              THEN
      
                lc_action := 'Formating card_expiration_date';
      
                lc_card_expiration_date := TO_CHAR(lr_contract_info.card_expiration_date, 'YYMM'); 
      
              END IF;
      
              /************************************************
              * Assigning invoice status based on authorization
              ************************************************/
              lc_action := 'Assiging invoice status based on authorizaiton';
      
              IF lr_contract_info.payment_type != 'AB'
              THEN
                IF lt_subscription_array(indx).auth_completed_flag = 'Y'
                THEN
                
                  lc_invoice_status  := 'OK';
                  
                  lc_failure_message := NULL;
                  
                  lc_auth_time       := lt_subscription_array(indx).auth_datetime;
                  
                  lc_next_retry_date := NULL;
                
                ELSE
                
                  lc_invoice_status  := 'FAIL';
                  
                  lc_failure_message := lt_subscription_array(indx).auth_message;
                  
                  lc_auth_time       := lt_subscription_array(indx).auth_datetime;
                  
                  lc_next_retry_date := NVL(lt_subscription_array(indx).initial_auth_attempt_date,SYSDATE) + lt_subscription_array(indx).next_retry_day;
                
                END IF;
              ELSE
              
                lc_invoice_status  := 'OK';
                
                lc_failure_message := NULL;
                
                lc_auth_time       := NULL;
      
              END IF;
      
              /**********************
              * Build history payload
              **********************/
      
              lc_action := 'Building history payload - header information';
      
              SELECT '{"billingHistoryRequest":{"transactionHeader":{"consumerName":"EBS","consumerTransactionId":"'
                         || lr_contract_info.contract_number||'-'|| lr_contract_info.initial_order_number||'-'|| lt_subscription_array(indx).billing_sequence_number||'-'
                         || TO_CHAR(SYSDATE,'DDMONYYYYHH24MISS')||'","consumerTransactionDateTime":"'|| TO_CHAR(SYSDATE,'YYYY-MM-DD')|| 'T'|| TO_CHAR(SYSDATE,'HH24:MI:SS')
                         ||'"},"customer":{"paymentDetails":{"paymentType":"'|| lr_contract_info.payment_type||'"}},"invoice":{"invoiceNumber":"'
                         ||  lt_subscription_array(indx).invoice_number||'","orderNumber":"'||lt_subscription_array(indx).initial_order_number||'","serviceContractNumber":"'
                         ||  lt_subscription_array(indx).contract_number||'","contractModifier":"'|| lr_contract_info.contract_number_modifier||'","billingSequenceNumber":"'
                         ||  lt_subscription_array(indx).billing_sequence_number||'","contractId":"'||  lt_subscription_array(indx).contract_id|| '","billingDate":"'
                         || TO_CHAR(lt_subscription_array(indx).billing_date,'DD-MON-YYYY')||'","invoiceDate":"'|| TO_CHAR(lr_invoice_header_info.trx_date,'DD-MON-YYYY')
                         ||'","invoiceTime":"'||TO_CHAR(lr_invoice_header_info.trx_date,'HH24:MI:SS')||'","invoiceStatus":"'|| lc_invoice_status||'","servicePeriodStartDate":"'
                         || TO_CHAR(lt_subscription_array(indx).service_period_start_date,'DD-MON-YYYY HH24:MI:SS')||'","servicePeriodEndDate":"'
                         || TO_CHAR(lt_subscription_array(indx).service_period_end_date,'DD-MON-YYYY HH24:MI:SS')||'","nextBillingDate":"'
                         || TO_CHAR(lt_subscription_array(indx).next_billing_date,'DD-MON-YYYY')||'","totals":{"subTotal":"'|| (ln_invoice_total_amount_info - lt_subscription_array(indx).tax_amount) 
                         || '","tax":"'|| TO_CHAR(lt_subscription_array(indx).tax_amount)||'","delivery": "String","discount":"String","misc":"String","total":"'|| ln_invoice_total_amount_info
                         || '"},"invoiceLines":{"invoiceLine":['
              INTO  lc_history_payload
              FROM  DUAL;
      
              lc_action := 'Building history payload - tender information';
      
              SELECT ']},"tenders":{"cardType":"'|| lr_contract_info.card_type||'","amount":"'||ln_invoice_total_amount_info||'","cardnumber":"'||lc_masked_credit_card_number
                          ||'","expirationDate":"'|| lc_card_expiration_date||'"}},"contract":{"contractLines":['
              INTO   lc_history_payload_tender
              FROM   DUAL;
      
              SELECT ']}}}'
              INTO     lc_parentheses
              FROM     dual;
      
              ln_loop_counter := ln_loop_counter + 1;
      
              lb_history_hrd_processed := TRUE;
      
            END IF;--lb_history_hrd_processed := FALSE;
      
            /******************************************************************
            * Calculating total line amount (contract_line_amount + tax_amount)
            ******************************************************************/
      
            lc_action := 'Calculating total line amount';
      
            lc_item_unit_total := lt_subscription_array(indx).total_contract_amount * lr_contract_line_info.quantity
                                         + NVL(lt_subscription_array(indx).tax_amount, 0);
      
            /***********************************
            * Build history payload - line level
            ***********************************/
      
            lc_action := 'Building history payload - line information';
      
            SELECT                 '{"orderLineNumber":"'|| lr_contract_line_info.initial_order_line||'","contractLineNumber":"'||lr_contract_line_info.contract_line_number
                                  || '","itemNumber":"'||lr_contract_line_info.item_name||'","contractStartDate":"'||TO_CHAR(lr_contract_line_info.contract_line_start_date,'YYYY-MM-DD')
                                  || '","contractEndDate":"'||TO_CHAR(lr_contract_line_info.contract_line_end_date,'YYYY-MM-DD')||'","billingFrequency":"'
                                  || lr_contract_line_info.contract_line_billing_freq|| '","unitPrice":"'|| lt_subscription_array(indx).contract_line_amount||'","tax":"'
                                  || NVL(lt_subscription_array(indx).tax_amount, 0)||'","unitTotal":"'|| lc_item_unit_total||'","failureMessage":"'|| lc_failure_message
                                  || '","initialAuthDate":"'|| TO_CHAR(NVL(lt_subscription_array(indx).initial_auth_attempt_date, TO_DATE(REPLACE(lt_subscription_array(indx).auth_datetime,'T', ' '),'yyyy-mm-dd hh24:mi:ss'))) ||'","lastAuthDate":"'
                                  || TO_CHAR(NVL(lt_subscription_array(indx).last_auth_attempt_date, TO_DATE(REPLACE(lt_subscription_array(indx).auth_datetime,'T', ' '),'yyyy-mm-dd hh24:mi:ss')))||'","nextRetryDate":"'|| TO_CHAR(lc_next_retry_date,'DD-MON-YYYY')||'"}'
            INTO   lc_history_payload_lines
            FROM   DUAL;
      
            SELECT '{"startDate":"'|| TO_CHAR(lr_contract_line_info.contract_line_start_date,'DD-MON-YYYY HH24:MI:SS')||'","endDate":"'
                  || TO_CHAR(lr_contract_line_info.contract_line_end_date,'DD-MON-YYYY HH24:MI:SS')||'","serviceType":"'|| lr_contract_line_info.program
                  || '","billingFrequency":"'|| lr_contract_line_info.contract_line_billing_freq|| '","vendorNumber":"'||lr_contract_line_info.vendor_number||'","lineNumber":"'
                  || lr_contract_line_info.contract_line_number|| '","contractLineAmount":"'|| lt_subscription_array(indx).contract_line_amount||'","totalContractLineAmount":"'
                  || lr_contract_line_info.contract_line_amount|| '"}'
            INTO   lc_contract_line
            FROM   DUAL;
      
            /************************************************
            * Need a comma between payload line level records
            ************************************************/
      
            IF ln_loop_counter = 1
            THEN
      
              lc_history_payload := lc_history_payload
                                    || ''
                                    || lc_history_payload_lines;
      
              lc_history_payload_tender := lc_history_payload_tender
                                           ||''
                                           ||lc_contract_line;
      
              ln_loop_counter := ln_loop_counter + 1;
      
            ELSE
      
              lc_history_payload := lc_history_payload
                                    || ','
                                    || lc_history_payload_lines;
      
              lc_history_payload_tender := lc_history_payload_tender
                                           ||','
                                           ||lc_contract_line;
      
              ln_loop_counter := ln_loop_counter + 1;
      
            END IF;
      
            /**********************************************************************************
            * This is the last lt_subscription_array record therefore appending tender payload,
            * sending payload, recording response. 
            *********************************************************************************/
      
            IF  (ln_loop_counter - 1) = lt_subscription_array.COUNT
            THEN
      
              lc_action := 'Concatenating tender information to history payload';
      
              lc_history_payload := lc_history_payload
                                    || ''
                                    || lc_history_payload_tender
                                    ||''
                                    || lc_parentheses;
                  
            END IF;--ln_loop_counter = lt_subscription_array.COUNT
      
          END IF;--lt_subscription_array(indx).billing_sequence_number != 1 end if
      
        EXCEPTION
          WHEN le_processing
          THEN
            fnd_file.put_line(fnd_file.LOG, 'Le Exception:' || SQLERRM);
            lr_subscription_error_info                         := NULL;
            lr_subscription_error_info.contract_id             := lt_subscription_array(indx).contract_id;
            lr_subscription_error_info.contract_number         := lt_subscription_array(indx).contract_number;
            lr_subscription_error_info.contract_line_number    := NULL;
            lr_subscription_error_info.billing_sequence_number := lt_subscription_array(indx).billing_sequence_number;
            lr_subscription_error_info.error_module            := lc_procedure_name;
            lr_subscription_error_info.error_message           := SUBSTR('Action: ' || lc_action || ' Error: ' || lc_error, 1, gc_max_err_size);
            lr_subscription_error_info.creation_date           := SYSDATE;
      
            lc_action := 'Calling insert_subscription_error_info';
      
            insert_subscription_error_info(p_subscription_error_info => lr_subscription_error_info);
            
            logit(p_message => 'contract_id : ' ||lt_subscription_array(indx).contract_id||' billing_sequence_number : ' ||lt_subscription_array(indx).billing_sequence_number
                  ||' failed to write to file',
            p_force   => TRUE);
      
            lc_error := SUBSTR(lr_subscription_error_info.error_message, 1, gc_max_sub_err_size);
      
            --RAISE le_processing;
      
          WHEN OTHERS
          THEN
            fnd_file.put_line(fnd_file.LOG, 'Othere Exception:' || SQLERRM);
            lr_subscription_error_info                         := NULL;
            lr_subscription_error_info.contract_id             := lt_subscription_array(indx).contract_id;
            lr_subscription_error_info.contract_number         := lt_subscription_array(indx).contract_number;
            lr_subscription_error_info.contract_line_number    := NULL;
            lr_subscription_error_info.billing_sequence_number := lt_subscription_array(indx).billing_sequence_number;
            lr_subscription_error_info.error_module            := lc_procedure_name;
            lr_subscription_error_info.error_message           := SUBSTR('Action: ' || lc_action || ' Error: ' || SQLCODE || ' ' || SQLERRM, 1, gc_max_err_size);
            lr_subscription_error_info.creation_date           := SYSDATE;
      
            lc_action := 'Calling insert_subscription_error_info';
      
            insert_subscription_error_info(p_subscription_error_info => lr_subscription_error_info);
            
            logit(p_message => 'contract_id : ' ||lt_subscription_array(indx).contract_id||' billing_sequence_number : ' ||lt_subscription_array(indx).billing_sequence_number
                  ||' failed to write to file',
            p_force   => TRUE);
      
            lc_error := SUBSTR(lr_subscription_error_info.error_message, 1, gc_max_sub_err_size);
      
            --RAISE le_processing;
        END;
      
      END LOOP; --sub loop
      
      BEGIN

        UTL_FILE.PUT_LINE(lt_file_handle,lc_history_payload);

      EXCEPTION
        WHEN OTHERS THEN
          fnd_file.put_line(fnd_file.LOG, 'Exception while writing data into file:' || SQLERRM);
          logit(p_message =>' Exception while writing data into file '|| SQLERRM || SQLCODE 
               ,p_force   => TRUE);
         --RAISE le_processing;
      END;
    
    END LOOP;--eligible contracts loop
    
    UTL_FILE.fclose (lt_file_handle);
    
    exiting_sub(p_procedure_name => lc_procedure_name);

  EXCEPTION

    WHEN le_skip
    THEN
      fnd_file.put_line(fnd_file.LOG, 'Exception Skipping:' || SQLERRM);
      logit(p_message => 'Skipping: ' || lc_error);

    WHEN le_processing
    THEN

      FOR indx IN 1 .. lt_subscription_array.COUNT
      LOOP

        logit(p_message => 'contract_id : ' ||lt_subscription_array(indx).contract_id||' billing_sequence_number : ' ||lt_subscription_array(indx).billing_sequence_number
                  ||' failed to write to file',
            p_force   => TRUE);

      END LOOP;

      exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => TRUE);
      --RAISE_APPLICATION_ERROR(-20101, lc_error);

    WHEN OTHERS
    THEN
      fnd_file.put_line(fnd_file.LOG, 'Exception2 others:' || SQLERRM);

      FOR indx IN 1 .. lt_subscription_array.COUNT
      LOOP

        logit(p_message => 'contract_id : ' ||lt_subscription_array(indx).contract_id||' billing_sequence_number : ' ||lt_subscription_array(indx).billing_sequence_number
                  ||' failed to write to file',
            p_force   => TRUE);

      END LOOP;

      exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => TRUE);
      RAISE_APPLICATION_ERROR(-20101, 'PROCEDURE: ' || lc_procedure_name || ' Action: ' || lc_action || ' SQLCODE: ' || SQLCODE || ' SQLERRM: ' || SQLERRM);

  END generate_bill_history_payload;
  
  /******************************************************************
  * Helper procedure to get trans id by performing $0 authorization
  ****************************************************************/

  PROCEDURE update_trans_id_scm(errbuff            OUT VARCHAR2,
                                retcode            OUT NUMBER,
                                p_debug_flag       IN  VARCHAR2 DEFAULT 'N')
  IS

    CURSOR c_eligible_contracts
    IS
    SELECT *
    FROM   xx_ar_contracts
    WHERE  cc_trans_id_source              = 'EBS'
    AND    NVL(cof_trans_id_scm_flag,'N') != 'Y';

    lc_procedure_name    CONSTANT  VARCHAR2(61) := gc_package_name || '.' || 'update_trans_id_scm';

    lt_parameters                  gt_input_parameters;

    lc_action                      VARCHAR2(1000);

    lc_error                       VARCHAR2(1000);

    lc_decrypted_value             xx_ar_contracts.card_token%TYPE;

    lc_trans_id_payload            VARCHAR2(32000);

    lc_expiration_date             VARCHAR2(4);

    l_request                      UTL_HTTP.req;

    l_response                     UTL_HTTP.resp;

    lclob_buffer                   CLOB;

    lc_buffer                      VARCHAR2(10000);

    lr_subscription_payload_info   xx_ar_subscription_payloads%ROWTYPE;

    le_processing                  EXCEPTION;
    
    lc_trans_id_scm_flag           xx_ar_contracts.cof_trans_id_scm_flag%TYPE;
    
    lc_payload_id                  NUMBER;    
    
    lc_transaction_code            VARCHAR2(60);
    
    lc_transaction_message         VARCHAR2(256);
    
    lt_program_setups              gt_translation_values;
    
    lc_transaction                 VARCHAR2(256);
    
    l_name                         VARCHAR2(256);
                                   
    l_value                        VARCHAR2(1024);

  BEGIN
    lt_parameters('p_debug_flag')       := p_debug_flag;

    entering_main(p_procedure_name   => lc_procedure_name,
                  p_rice_identifier  => 'E7044',
                  p_debug_flag       => p_debug_flag,
                  p_parameters       => lt_parameters);
    
    
    lc_action := 'Calling get_program_setups';

    get_program_setups(x_program_setups => lt_program_setups);
    
    /*******************************************************************************
    * If passed in p_debug_flag IS N, check if debug is enabled in translation table
    *******************************************************************************/

    IF (p_debug_flag != 'Y' AND lt_program_setups('enable_debug') = 'Y')
    THEN

      lc_action := 'Calling set_debug';

      set_debug(p_debug_flag => lt_program_setups('enable_debug'));

    END IF;
    
    /******************************************************************
    *  Loop thru contracts which are eligible to update trans_id to SCM
    ******************************************************************/

    lc_action := 'Calling c_eligible_contracts cursor';

    FOR eligible_contract_rec IN c_eligible_contracts
    LOOP
      
      BEGIN
      
        /************************************************************************
        * Keep track of the contract number and billing sequence being worked on.
        ************************************************************************/
        
        lc_transaction := 'Processing contract_id: ' || eligible_contract_rec.contract_id;
        
        logit(p_message => 'Transaction: ' || lc_transaction);
        
        /**************
        * Decrypt Value
        **************/
        
        lc_action := 'Calling decrypt_credit_card';
        
        decrypt_credit_card(p_context_namespace => 'XX_AR_SUBSCRIPTIONS_MT_CTX',
                            p_context_attribute => 'TYPE',
                            p_context_value     => 'OM',
                            p_module            => 'HVOP',
                            p_format            => 'EBCDIC',
                            p_encrypted_value   => eligible_contract_rec.card_token,
                            p_key_label         => eligible_contract_rec.card_encryption_label,
                            x_decrypted_value   => lc_decrypted_value);
        
        /***********************
        * Format expiration date
        ***********************/
        
        IF eligible_contract_rec.card_expiration_date IS NOT NULL
        THEN
          lc_expiration_date := TO_CHAR(eligible_contract_rec.card_expiration_date, 'MMYY');
        END IF;
        
        /****************************
        * Build authorization payload
        ****************************/
        
        lc_action := 'Building authorization payload';
        
        SELECT '{
                    "updatePaymentInfoRequest": {
                        "transactionHeader": {
                            "consumer": {
                                "consumerName": "EBS",
                                "consumerTransactionID": "'
                                       || eligible_contract_rec.contract_number
                                       || '-'
                                       || TO_CHAR(SYSDATE,
                                                  'DDMONYYYYHH24MISS')
                                       || '",
                                "altTrackingIDs": null,
                                "moniker": null
                            },
                            "transactionId": null,
                            "timeReceived": null
                        },
                        "customer": {
                            "paymentDetails": {
                                "paymentType": "'
                                       || eligible_contract_rec.payment_type
                                       || '",
                                    "paymentCard": {
                                        "cardNumber": "",
                                        "cardHighValueToken": "'
                                            || lc_decrypted_value
                                            || '",
                                        "expirationDate": "'
                                            || lc_expiration_date
                                            || '",
                                        "cardType": "'
                                            || eligible_contract_rec.card_type
                                            || '",
                                        "billingAgreementId": "",
                                        "walletId": "",
                                        "keyLabel": "",
                                        "encryptionHash": "",
                                        "cofTransactionId": "'
                                            || eligible_contract_rec.cc_trans_id
                                            || '"
                                    }
                            }
                        },
                        "order": {
                            "orderNumber": "'
                                    || eligible_contract_rec.contract_name
                                    || '",
                            "contractId": "'
                                    || eligible_contract_rec.contract_id
                                    || '"
                        }
                    }
                  }'
        INTO lc_trans_id_payload
        FROM dual;
        
        lc_action := 'Validating Wallet location';
            
        IF lt_program_setups('wallet_location') IS NOT NULL
        THEN
        
          lc_action := 'calling UTL_HTTP.set_wallet';
        
          UTL_HTTP.SET_WALLET(lt_program_setups('wallet_location'), lt_program_setups('wallet_password'));
        
        END IF;
        
        lc_action := 'Calling UTL_HTTP.begin_request';
        
        l_request := UTL_HTTP.begin_request(lt_program_setups('update_trans_id_scm_url'), 'POST', ' HTTP/1.1');
        
        lc_action := 'Calling UTL_HTTP.set_header';
        
        UTL_HTTP.set_header(l_request, 'user-agent', 'mozilla/4.0');
        
        UTL_HTTP.set_header(l_request, 'content-type', 'application/json');
        
        UTL_HTTP.set_header(l_request, 'Content-Length', LENGTH(lc_trans_id_payload));
        
        UTL_HTTP.set_header(l_request, 'Authorization', 'Basic ' || UTL_RAW.cast_to_varchar2(UTL_ENCODE.base64_encode(UTL_RAW.cast_to_raw(lt_program_setups('update_trans_id_scm_user')
                                                                                                                                          || ':' ||
                                                                                                                                          lt_program_setups('update_trans_id_scm_pwd')
                                                                                                                                          ))));
        lc_action := 'Calling UTL_HTTP.write_text';
        
        UTL_HTTP.write_text(l_request, lc_trans_id_payload);
        
        lc_action := 'Calling UTL_HTTP.get_response';
        
        l_response := UTL_HTTP.get_response(l_request);
        
        COMMIT;
        
        logit(p_message => 'Response status_code' || l_response.status_code);
        logit(p_message => 'Response phrase ' || l_response.reason_phrase);
        
        FOR i IN 1..UTL_HTTP.GET_HEADER_COUNT(l_response)
        LOOP
          UTL_HTTP.GET_HEADER(l_response, i, l_name, l_value);
          fnd_file.put_line(fnd_file.LOG,l_name || ': ' || l_value);
        END LOOP;
        
        BEGIN
          lclob_buffer := EMPTY_CLOB;
          LOOP
            UTL_HTTP.read_text(l_response, lc_buffer, LENGTH(lc_buffer));
            lclob_buffer := lclob_buffer || lc_buffer;
          END LOOP;
        
          logit(p_message => 'Response Clob: ' || lclob_buffer);
        
          UTL_HTTP.end_response(l_response);
        
        EXCEPTION
        WHEN UTL_HTTP.end_of_body
        THEN
           UTL_HTTP.end_response(l_response);
        END;
        
        /********************
        * Masking credit card
        ********************/
        
        IF lc_decrypted_value IS NOT NULL
        THEN
          lc_action := 'Masking credit card';
        
          lc_trans_id_payload := REPLACE(lc_trans_id_payload, lc_decrypted_value, SUBSTR(lc_decrypted_value, 1, 6) || '*****' || SUBSTR(lc_decrypted_value, LENGTH(lc_decrypted_value) - 4, 4));
        END IF;
        
        /***********************
        * Store request/response
        ***********************/
        
        lc_action := 'Store request/response';
        
        lc_payload_id := xx_ar_subscription_payloads_s.NEXTVAL;
        
        lr_subscription_payload_info.payload_id              := lc_payload_id;
        lr_subscription_payload_info.response_data           := lclob_buffer;
        lr_subscription_payload_info.creation_date           := SYSDATE;
        lr_subscription_payload_info.created_by              := FND_GLOBAL.USER_ID;
        lr_subscription_payload_info.last_updated_by         := FND_GLOBAL.USER_ID;
        lr_subscription_payload_info.last_update_date        := SYSDATE;
        lr_subscription_payload_info.input_payload           := lc_trans_id_payload;
        lr_subscription_payload_info.contract_number         := eligible_contract_rec.contract_number;
        lr_subscription_payload_info.billing_sequence_number := NULL;
        lr_subscription_payload_info.contract_line_number    := NULL;
        lr_subscription_payload_info.source                  := lc_procedure_name;
        
        lc_action := 'Calling insert_subscription_payload_info';
        
        insert_subscript_payload_info(p_subscription_payload_info => lr_subscription_payload_info);
        
        /*************************
        * Get response into a CLOB
        *************************/
        
        IF (l_response.status_code != 200)
        THEN
          lc_error := 'Failed response status_code: ' || l_response.status_code;
          RAISE le_processing;
        END IF;
        
        BEGIN
          SELECT jt0.transaction_code,
                 jt0.transaction_message
          INTO   lc_transaction_code,
                 lc_transaction_message
          FROM   xx_ar_subscription_payloads auth_response,
                 JSON_TABLE ( auth_response.response_data, '$.updatePaymentInfoResponse.transactionStatus' COLUMNS ( "TRANSACTION_CODE" VARCHAR2(60) PATH '$.code' ,"TRANSACTION_MESSAGE" VARCHAR2(256) PATH '$.message' )) "JT0" 
          WHERE  auth_response.payload_id = lc_payload_id;
        EXCEPTION
          WHEN OTHERS THEN
            lc_error := 'Failed transaction code: ' || lc_transaction_code;
            logit('ERROR : '||SQLERRM);
            logit('lc_transaction_code : '||lc_transaction_code);
            logit('lc_transaction_message : '||lc_transaction_message);
            RAISE le_processing;
        END;
        
        IF lc_transaction_code = '00'
        THEN
          UPDATE xx_ar_contracts
          SET    cof_trans_id_scm_flag = 'Y'
          WHERE  contract_id           = eligible_contract_rec.contract_id;
          
          COMMIT;
        ELSE
          UPDATE xx_ar_contracts
          SET    cof_trans_id_scm_flag = 'E'
          WHERE  contract_id           = eligible_contract_rec.contract_id;
          
          COMMIT;
        END IF;
      
      EXCEPTION
        WHEN le_processing 
        THEN
          errbuff := 'Error encountered. Please check logs';
         
          logit(p_message => 'ERROR Transaction: ' || lc_transaction || ' Action: ' || lc_action || ' SQLCODE: ' || SQLCODE || ' SQLERRM: ' || SQLERRM,
                p_force   => TRUE);
          logit(p_message => 'ERROR: ' || lc_error,
                p_force   => TRUE);
          logit(p_message      => '-----------------------------------------------',
                p_force   => TRUE);
        WHEN OTHERS 
        THEN
          errbuff := 'Error encountered. Please check logs';
         
          logit(p_message => 'ERROR Transaction: ' || lc_transaction || ' Action: ' || lc_action || ' SQLCODE: ' || SQLCODE || ' SQLERRM: ' || SQLERRM,
                p_force   => TRUE);
          logit(p_message => 'ERROR: ' || lc_error,
                p_force   => TRUE);
          logit(p_message      => '-----------------------------------------------',
                p_force   => TRUE);
      END;
    END LOOP;
  
    exiting_sub(p_procedure_name => lc_procedure_name);
     
  EXCEPTION      
    WHEN OTHERS
    THEN
    
      retcode := 2;

      errbuff := 'Error encountered. Please check logs';
      
      logit(p_message => 'ERROR Transaction: ' || lc_transaction || ' Action: ' || lc_action || ' SQLCODE: ' || SQLCODE || ' SQLERRM: ' || SQLERRM,
            p_force   => TRUE);
      logit(p_message      => '-----------------------------------------------',
            p_force   => TRUE);
      
      exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => TRUE);

  END update_trans_id_scm;

  /********************************************************************
  * Helper procedure to purge subscription payload and Error table data
  ********************************************************************/
 
  PROCEDURE xx_ar_subs_payload_purge_prc (errbuff   OUT       VARCHAR2,
                                          retcode   OUT       NUMBER
                                         ) 
  AS

    CURSOR xx_ar_payload_data_cur 
    IS
      SELECT  *
      FROM  xx_ar_subscription_payloads
      WHERE  1              = 1
      AND  creation_date <= SYSDATE - 30;

    CURSOR xx_ar_suberrtb_data_cur 
    IS
      SELECT contract_number,
             contract_line_number,
             contract_id,
             error_message,
             billing_sequence_number,
             error_module,
             creation_date,
             ROWID
      FROM xx_ar_subscriptions_error
      WHERE 1             = 1
      AND creation_date <= SYSDATE - 30;

    lc_tot_rec_cnt1   NUMBER;
    lc_rem_rec_cnt1   NUMBER;
    lc_count1         NUMBER         := 0;
    lc_tot_rec_cnt    NUMBER;
    lc_rem_rec_cnt    NUMBER;
    lc_count          NUMBER         := 0;

  BEGIN
    BEGIN

      /*************************
      * Getting total data count
      *************************/

      SELECT COUNT(*)
      INTO lc_tot_rec_cnt
      FROM xx_ar_subscription_payloads
      WHERE 1    = 1;

      logit(p_message =>' +---------------------------------------------------------------------------+ ', p_force   => TRUE);
      logit(p_message =>' *** Subscrption Payload Record Details *** ');
      logit(p_message =>' +---------------------------------------------------------------------------+ ', p_force   => TRUE);
      logit(p_message =>' +---------------------------------------------------------------------------+ ', p_force   => TRUE);
      logit(p_message =>' *** Subscrption Payload Record Details *** ');
      logit(p_message =>' +---------------------------------------------------------------------------+ ', p_force   => TRUE);
      logit(p_message =>' Before Purge: Total Subscription Payload Records : ' || lc_tot_rec_cnt, p_force   => TRUE         );

    EXCEPTION
      WHEN no_data_found 
      THEN 
        NULL;
    END;

    BEGIN

      /*****************************
      * Getting remaining data count
      *****************************/

      SELECT COUNT(*)
      INTO lc_rem_rec_cnt
      FROM xx_ar_subscription_payloads
      WHERE 1             = 1
      AND creation_date >= SYSDATE - 30;

      logit(p_message =>' Before Purge: Less than 30 days Payload Records : ' || lc_rem_rec_cnt, p_force   => TRUE);

    EXCEPTION
      WHEN no_data_found 
      THEN 
        NULL;
    END;

    BEGIN
      FOR payload_data_rec IN xx_ar_payload_data_cur 
      LOOP
        DELETE xx_ar_subscription_payloads
        WHERE payload_id = payload_data_rec.payload_id; 

        lc_count := lc_count + 1;

      END LOOP; 

      COMMIT;
      
      logit(p_message =>' Total Subscription Payload - Purged Records : ' || lc_count, p_force   => TRUE);
      
    EXCEPTION
      WHEN no_data_found 
      THEN
        NULL;
      WHEN OTHERS 
      THEN
        ROLLBACK;

        retcode := 1;
        errbuff := 'Error encountered. Please check logs';
        logit(p_message =>' Exception while writing data into file '|| SQLERRM || SQLCODE, p_force   => TRUE);

    END;

    BEGIN

      /*************************
      * Getting total data count
      *************************/
      SELECT COUNT(*)
      INTO lc_tot_rec_cnt1
      FROM xx_ar_subscriptions_error
      WHERE 1     = 1;

        logit(p_message => ' +---------------------------------------------------------------------------+ ' , p_force   => TRUE);
        logit(p_message => ' *** Subscrption Error Table Record Details *** ');
        logit(p_message => ' +---------------------------------------------------------------------------+ ' , p_force   => TRUE);
        logit(p_message => ' +---------------------------------------------------------------------------+ ' , p_force   => TRUE);
        logit(p_message => ' *** Subscrption Error Table Record Details *** ');
        logit(p_message => ' +---------------------------------------------------------------------------+ ' , p_force   => TRUE);
        logit(p_message => ' Before Purge: Total Subscription Errored Records : ' || lc_tot_rec_cnt1, p_force   => TRUE);
    
    EXCEPTION
      WHEN no_data_found
      THEN
        NULL;
    END;

    BEGIN

      /*****************************
      * Getting remaining data count
      *****************************/

      SELECT COUNT(*)
      INTO lc_rem_rec_cnt1
      FROM xx_ar_subscriptions_error
      WHERE 1             = 1
      AND creation_date >= SYSDATE - 30;

      logit(p_message => ' Before Purge: Less than 30 days Subscription Errored Records: ' || lc_rem_rec_cnt1, p_force   => TRUE);
   
    EXCEPTION
      WHEN no_data_found 
      THEN
        NULL;
    END;

    BEGIN
      FOR suberrtb_data_rec IN xx_ar_suberrtb_data_cur 
      LOOP
        DELETE XX_AR_SUBSCRIPTIONS_ERROR
        WHERE ROWID = suberrtb_data_rec.ROWID; 

        lc_count1 := lc_count1 + 1;

      END LOOP; 

      COMMIT;

      logit(p_message => ' Total Subscription Error Table - Purged Records : ' || lc_count1, p_force   => TRUE);

    EXCEPTION
      WHEN no_data_found 
      THEN
        NULL;
      WHEN OTHERS 
      THEN 
        ROLLBACK;

       retcode := 1;
       errbuff := 'Error encountered. Please check logs';
       logit(p_message =>' Exception while writing data into file '|| SQLERRM || SQLCODE, p_force   => TRUE);
 
    END;

  END xx_ar_subs_payload_purge_prc;
    
  /**********************************************
  * Helper procedure to validate relocation store
  **********************************************/
  
  PROCEDURE xx_relocation_store_vald_prc(errbuff         OUT       VARCHAR2,
                                         retcode         OUT       NUMBER
                                          )
  AS
    lc_procedure_name  CONSTANT VARCHAR2(61) := gc_package_name || '.' || 'xx_relocation_store_vald_prc';
    lt_parameters      gt_input_parameters;
    lc_count NUMBER := 0;

     /**************************************************
     * Taking target_value2 from Store Close translation
     **************************************************/
     CURSOR xx_target_val_cur 
     IS
       SELECT   LPAD(vals.target_value2,6,'0') relocated_store
       FROM   xx_fin_translatevalues                     vals,
              xx_fin_translatedefinition                 defn
       WHERE   defn.translate_id                        = vals.translate_id
       AND   defn.translation_name                    = 'SUBSCRIPTION_STORE_CLOSE'
       AND   SYSDATE BETWEEN vals.start_date_active AND NVL(vals.end_date_active, SYSDATE + 1)  
       AND   SYSDATE BETWEEN defn.start_date_active AND NVL(defn.end_date_active, SYSDATE + 1)
       AND   SYSDATE                                 >= to_date(vals.target_value4,'MM-DD-YYYY')

       AND   vals.enabled_flag                        = 'Y'
       AND   defn.enabled_flag                        = 'Y';
 
  BEGIN

    entering_sub(p_procedure_name  => lc_procedure_name,
                 p_parameters      => lt_parameters);
   
     
    logit(p_message =>' BEGIN : Relocation Store Validation : ');

    FOR target_location_rec IN xx_target_val_cur 
    LOOP

      select count(1)
      into  lc_count
      FROM hr_locations_all              hla
          ,hr_all_organization_units haou
          ,hr_lookups                    hl
      where 1=1
      and hla.location_id  =haou.location_id
      and haou.type        =hl.lookup_code
      and hl.lookup_type  ='ORG_TYPE'
      and hl.enabled_flag ='Y'
      and SUBSTR(hla.LOCATION_CODE,1,6)=target_location_rec.relocated_store;

      IF lc_count = 0 
      THEN
        logit(p_message =>' Location Store is not defined in HR LOCATION ' || target_location_rec.relocated_store, p_force   => TRUE);
      ELSE
        fnd_file.put_line(fnd_file.OUTPUT, 'Location Store is defined in HR LOCATION : '          ||target_location_rec.relocated_store);
      END IF;

    END LOOP;

    logit(p_message =>' END : Relocation Store Validation : ');

  EXCEPTION
    WHEN OTHERS
    THEN
      null;
      exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => TRUE);
      RAISE_APPLICATION_ERROR(-20101, 'PROCEDURE: ' || lc_procedure_name || ' SQLCODE: ' || SQLCODE || ' SQLERRM: ' || SQLERRM);
  END xx_relocation_store_vald_prc;
  
  /**********************************************************************************************
  * Helper Procedure to display the Invoices and the Receipt numbers as part of Receipt Updation
  ***********************************************************************************************/
  
  PROCEDURE printit(p_out_message  IN  VARCHAR2)
  IS
    lc_out_message  VARCHAR2(2000) := NULL;
  BEGIN
      lc_out_message := SUBSTR(p_out_message,1, gc_max_print_size);
      IF (fnd_global.conc_request_id > 0)
      THEN
        fnd_file.put_line(fnd_file.output, lc_out_message);
      END IF;
  EXCEPTION
      WHEN OTHERS
      THEN
          NULL;
  END printit;
  
  /********************************************************************************
  * Helper procedure to update receipt number and required flags for AB Customers
  *********************************************************************************/
  
  PROCEDURE txn_receiptnum_update(errbuff       OUT VARCHAR2,
                                  retcode       OUT VARCHAR2,
                                  p_debug_flag  IN  VARCHAR2)
  AS
    CURSOR c_ab_txnnum
    IS
      SELECT DISTINCT XAS.invoice_number,XAS.contract_number,XAS.contract_id,RCTA.customer_trx_id,XAS.billing_sequence_number,
                      (SELECT SUM(RCTLA.extended_amount) 
                       FROM   ra_customer_trx_lines_all RCTLA 
                       WHERE  RCTLA.customer_trx_id = RCTA.customer_trx_id)txn_amount
      FROM   xx_ar_subscriptions XAS,
             ra_customer_trx_all RCTA,
             xx_ar_contracts XAC,
             xx_ar_contract_lines XACL
      WHERE  XAC.payment_type            = 'AB'
      AND    XAC.contract_id             = XAS.contract_id
      AND    XAS.invoice_created_flag    = 'Y'
      AND    XAS.invoice_number is not null
      AND    XAS.receipt_created_flag    <> 'Y'
      AND    XAS.billing_sequence_number > XACL.initial_billing_sequence
      AND    XAS.contract_id             = XACL.contract_id
      AND    XAS.contract_line_number    = XACL.contract_line_number
      AND    XAC.contract_id             = XACL.contract_id
      AND    XAS.invoice_number          = RCTA.trx_number;
      

    CURSOR c_contract_lines (p_invoice_number IN VARCHAR2,p_contract_id IN NUMBER)
    IS 
      SELECT XAS.subscriptions_id,XAS.contract_line_number
      FROM   xx_ar_subscriptions XAS
      WHERE  XAS.invoice_number          = p_invoice_number
      AND    XAS.contract_id             = p_contract_id;

    CURSOR c_cash_receiptid (p_customer_trx_id IN NUMBER)
    IS 
      SELECT ARAA.cash_receipt_id,ARAA.receivable_application_id 
      FROM   ar_receivable_applications_all ARAA
      WHERE  ARAA.applied_customer_trx_id = p_customer_trx_id
      AND    ARAA.status = 'APP'
      AND    ARAA.receivable_application_id IN (SELECT MAX(ARAA1.receivable_application_id)
                                                FROM ar_receivable_applications_all ARAA1
                                                WHERE ARAA1.applied_customer_trx_id = ARAA.applied_customer_trx_id 
                                                AND   ARAA1.cash_receipt_id = ARAA.cash_receipt_id
                                               )
      ORDER  BY 1;

    lt_program_setups       gt_translation_values;
    lr_contract_info        xx_ar_contracts%ROWTYPE;
    lt_subscription_array   subscription_table;    
    lc_procedure_name       CONSTANT VARCHAR2(61)                               := gc_package_name || '.' || 'txn_receiptnum_update';
    ln_cash_receipt_id      ar_receivable_applications_all.cash_receipt_id%TYPE := 0;
    lc_receipt_num          ar_cash_receipts_all.receipt_number%TYPE            := NULL;
    ln_cnt_cash_receipts    NUMBER                                              := 0;
    lc_prev_receipt_num     ar_cash_receipts_all.receipt_number%TYPE            := NULL;
    lc_curr_receipt_num     ar_cash_receipts_all.receipt_number%TYPE            := NULL;
    ln_receipt_num_count    NUMBER                                              := 0;
    ln_tot_receipt_amt      NUMBER                                              := 0;
    lc_receipt_created_flag VARCHAR2(1)                                         := NULL;
    ln_prev_receipt_amt     NUMBER                                              := 0;
    lc_send_bill_hist_flag  VARCHAR2(1)                                         := 'N';
    BEGIN
    set_debug(p_debug_flag => p_debug_flag);
    logit(p_message => '---------------------------------------------------',
          p_force   => TRUE);
    logit(p_message => 'Starting TXN_RECEIPTNUM_UPDATE routine. ',
          p_force   => TRUE);
    logit(p_message => '---------------------------------------------------',
          p_force   => TRUE);
    printit(p_out_message => RPAD ('-',180 , '-'));
    printit(p_out_message => 'Details of the Contract, Invoice and the Receipt Numbers updated in the Subscriptions Table for AB Customers');
    printit(p_out_message => RPAD ('-',180 , '-'));
    printit(p_out_message => RPAD ('CONTRACT#', 20, ' ') || ' ' ||RPAD ('INVOICE#', 20, ' ') || ' ' || RPAD ('RECEIPT#', 20, ' '));
    printit(p_out_message => RPAD ('-', 20, '-') || ' ' || RPAD ('-', 20, '-') || ' ' || RPAD ('-', 20, '-')); 
    FOR ab_txnnum_rec IN c_ab_txnnum
      LOOP
      /**************************************************************************************
      * LOOP Through the Transaction Number for which the Receipt Numbers have to be updated.
      ***************************************************************************************/
      ln_cash_receipt_id   := 0;
      lc_receipt_num       := NULL;
      ln_cnt_cash_receipts := 0;
      lc_curr_receipt_num  := NULL;
      logit(p_message => '--------------------------------------------------------------------------------------------------------------------------------',
            p_force   => TRUE);
      logit(p_message => 'START of updating Record of Invoice# : ' || ab_txnnum_rec.invoice_number || ' for Contract #: ' || ab_txnnum_rec.contract_number,
            p_force   => TRUE);
      logit(p_message => '--------------------------------------------------------------------------------------------------------------------------------',
            p_force   => TRUE);
      BEGIN
          SELECT COUNT(ARAA.cash_receipt_id)
          INTO   ln_cnt_cash_receipts
          FROM   ar_receivable_applications_all ARAA
          WHERE  ARAA.applied_customer_trx_id = ab_txnnum_rec.customer_trx_id;
      EXCEPTION
          WHEN OTHERS 
          THEN
            ln_cnt_cash_receipts := 0;
      END;
         IF ln_cnt_cash_receipts > 0 
         THEN
               
               ln_receipt_num_count    := 0;
               ln_tot_receipt_amt      := 0; 
               lc_receipt_created_flag := NULL;

               FOR cash_receiptid_rec IN c_cash_receiptid (ab_txnnum_rec.customer_trx_id)
                  LOOP
                    lc_prev_receipt_num  := NULL;
                    ln_prev_receipt_amt  := 0;

                    BEGIN
                      SELECT ACRA.receipt_number,ARAA.amount_applied
                      INTO   lc_prev_receipt_num,ln_prev_receipt_amt
                      FROM   ar_cash_receipts_all ACRA,
                             ar_receivable_applications_all ARAA
                      WHERE  ACRA.cash_receipt_id = cash_receiptid_rec.cash_receipt_id
                      AND    ARAA.receivable_application_id = cash_receiptid_rec.receivable_application_id
                      AND    ACRA.cash_receipt_id = ARAA.cash_receipt_id
                      AND    ARAA.applied_customer_trx_id = ab_txnnum_rec.customer_trx_id
                      AND    ARAA.status = 'APP';
                    EXCEPTION
                    WHEN OTHERS
                    THEN 
                      lc_prev_receipt_num := NULL;
                      ln_prev_receipt_amt := 0;
                    END;
                    
                    IF  (lc_prev_receipt_num IS NOT NULL)
                    THEN
                      ln_tot_receipt_amt     := ln_tot_receipt_amt + ln_prev_receipt_amt;
                    END IF;
                  END LOOP;

                BEGIN
                     SELECT MAX(ACRA.receipt_number)
                     INTO   lc_curr_receipt_num
                     FROM   ar_cash_receipts_all ACRA,
                            ar_receivable_applications_all ARAA
                     WHERE  ARAA.applied_customer_trx_id = ab_txnnum_rec.customer_trx_id
                     AND    ARAA.status = 'APP'
                     AND    ARAA.receivable_application_id IN (SELECT MAX(ARAA1.receivable_application_id)
                                                               FROM   ar_receivable_applications_all ARAA1
                                                               WHERE  ARAA1.applied_customer_trx_id = ARAA.applied_customer_trx_id 
                                                               AND    ARAA1.cash_receipt_id = ARAA.cash_receipt_id
                                                               )
                     AND    ACRA.cash_receipt_id = ARAA.cash_receipt_id;
                EXCEPTION       
                WHEN OTHERS
                     THEN lc_curr_receipt_num := NULL;
                END;
                IF (ln_tot_receipt_amt < ab_txnnum_rec.txn_amount)
                THEN
                   lc_receipt_created_flag := 'P';
                ELSIF(ln_tot_receipt_amt = ab_txnnum_rec.txn_amount)
                THEN
                   lc_receipt_created_flag := 'Y';   
                END IF;
               IF (lc_curr_receipt_num IS NOT NULL) 
               THEN
               FOR contract_lines_rec IN c_contract_lines (ab_txnnum_rec.invoice_number,ab_txnnum_rec.contract_id)
                  LOOP
                    logit(p_message => '--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------',
                          p_force   => TRUE);
                    logit(p_message => 'Updation of Receipt Number and other Flags for Contract id # : ' || ab_txnnum_rec.contract_id || ' Subscriptions id#: ' || contract_lines_rec.subscriptions_id || ' and  Contract Line#: ' || contract_lines_rec.contract_line_number,
                          p_force   => TRUE);
                    logit(p_message => '--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------',
                          p_force   => TRUE); 
                   
                      UPDATE xx_ar_subscriptions XAS
                      SET    XAS.receipt_number       = lc_curr_receipt_num,
                             XAS.receipt_created_flag = lc_receipt_created_flag,
                             XAS.ordt_staged_flag     = 'Y',
                             XAS.email_sent_flag      = 'Y',
                             XAS.last_update_date     = SYSDATE
                      WHERE  XAS.contract_line_number = contract_lines_rec.contract_line_number
                      AND    XAS.subscriptions_id     = contract_lines_rec.subscriptions_id;
                   END LOOP;

                 BEGIN

                   get_contract_info(p_contract_id     => ab_txnnum_rec.contract_id,
                                    x_contract_info   => lr_contract_info);


                   lt_subscription_array.delete();

                   get_subscription_array(p_contract_id             => ab_txnnum_rec.contract_id,
                                         p_billing_sequence_number => ab_txnnum_rec.billing_sequence_number,
                                         x_subscription_array      => lt_subscription_array);

                   get_program_setups(x_program_setups => lt_program_setups);

                   send_billing_history(p_program_setups      => lt_program_setups,
                                       p_contract_info       => lr_contract_info,
                                       px_subscription_array => lt_subscription_array);
                EXCEPTION
                    WHEN OTHERS THEN 
                    NULL;
                END;
 
                FOR contract_lines_rec IN c_contract_lines (ab_txnnum_rec.invoice_number,ab_txnnum_rec.contract_id)
                  LOOP
                    logit(p_message => '--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------',
                          p_force   => TRUE);
                    logit(p_message => 'Updation of History Sent Flag for Contract id # : ' || ab_txnnum_rec.contract_id || ' Subscriptions id#: ' || contract_lines_rec.subscriptions_id || ' and  Contract Line#: ' || contract_lines_rec.contract_line_number,
                          p_force   => TRUE);
                    logit(p_message => '--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------',
                          p_force   => TRUE); 
                   
                      UPDATE xx_ar_subscriptions XAS
                      SET    XAS.history_sent_flag    = 'Y'
                      WHERE  XAS.contract_line_number = contract_lines_rec.contract_line_number 
                      AND    XAS.subscriptions_id     = contract_lines_rec.subscriptions_id;
                   END LOOP;  

                END IF; 
          END IF;
          IF (lc_curr_receipt_num IS NOT NULL) 
          THEN
            logit(p_message => '-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------',
                  p_force   => TRUE);
            logit(p_message => 'End of Updating Record of Invoice# : ' || ab_txnnum_rec.invoice_number || ' with Receipt #: ' || lc_curr_receipt_num || ' having total Receipt Amount: ' || ln_tot_receipt_amt,
                  p_force   => TRUE);
            logit(p_message => '-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------',
                  p_force   => TRUE);
            printit(p_out_message => RPAD (ab_txnnum_rec.contract_number, 20, ' ') || ' ' || RPAD (ab_txnnum_rec.invoice_number, 20, ' ') || ' ' || RPAD (lc_curr_receipt_num, 20, ' '));
          ELSIF (lc_curr_receipt_num IS NULL)
          THEN
            lc_curr_receipt_num := 'No Receipt exists';
            logit(p_message => '-----------------------------------------------------------------------',
                  p_force   => TRUE);
            logit(p_message => lc_curr_receipt_num ||' for Invoice# : ' || ab_txnnum_rec.invoice_number,
                  p_force   => TRUE);
            logit(p_message => '-----------------------------------------------------------------------',
                  p_force   => TRUE);
            printit(p_out_message => RPAD (ab_txnnum_rec.contract_number, 20, ' ') || ' ' || RPAD (ab_txnnum_rec.invoice_number, 20, ' ') || ' ' || RPAD (lc_curr_receipt_num, 20, ' '));
          END IF;
      END LOOP;
     COMMIT;
    EXCEPTION
    WHEN OTHERS
    THEN
       logit(p_message => '---------------------------------------------------------------------------------------------------------------',
             p_force   => TRUE);
       logit(p_message => 'Exception while Submitting the Receipt Updation Program ' || ' SQLCODE: ' || SQLCODE || ' SQLERRM: ' || SQLERRM,
             p_force   => TRUE);
       logit(p_message => '---------------------------------------------------------------------------------------------------------------',
             p_force   => TRUE);
       RAISE_APPLICATION_ERROR(-20101, 'PROCEDURE: ' || lc_procedure_name || ' SQLCODE: ' || SQLCODE || ' SQLERRM: ' || SQLERRM);
    END txn_receiptnum_update;
  
  /***********************************************************************************
  * Procedure to write off invoice related to TERMINATED AND CLOSED contracts in SCM *
  ***********************************************************************************/
  PROCEDURE process_adjustments(errbuff        OUT VARCHAR2
                               ,retcode        OUT NUMBER
                               ,p_debug_flag   IN  VARCHAR2 DEFAULT 'N'
                               )
  IS

    CURSOR c_inv_adjustment
    IS
    SELECT rct.customer_trx_id, aps.payment_schedule_id, aps.amount_due_remaining,rct.trx_number,aps.status
    FROM   xx_ar_contracts xac
          ,xx_ar_subscriptions xas
          ,xx_ar_contract_lines xacl
          ,ra_customer_trx_all rct
          ,ar_payment_schedules_all aps
    WHERE xac.contract_id              = xas.contract_id
    AND   xac.contract_id              = xacl.contract_id
    AND   xacl.contract_line_number    = xas.contract_line_number
    AND   xas.billing_sequence_number >= xacl.initial_billing_sequence 
    AND   xas.invoice_number           = rct.trx_number
    AND   rct.customer_trx_id          = aps.customer_trx_id
    and   xas.invoice_created_flag     = 'Y' 
    AND   xas.auth_completed_flag     != 'Y'
    and   xac.payment_type            != 'AB'
    AND   aps.STATUS                   = 'OP'
    AND   (xas.contract_status= 'TERMINATE' OR TRUNC(NVL(xacl.close_date,SYSDATE+1)) < TRUNC(SYSDATE))
    UNION
    SELECT rct.customer_trx_id, aps.payment_schedule_id, aps.amount_due_remaining,rct.trx_number,aps.status
    FROM   xx_ar_contracts xac
          ,xx_ar_subscriptions xas
          ,xx_ar_contract_lines xacl
          ,ra_customer_trx_all rct
          ,ar_payment_schedules_all aps
    WHERE xac.contract_id              = xas.contract_id
    AND   xac.contract_id              = xacl.contract_id
    AND   xacl.contract_line_number    = xas.contract_line_number
    AND   xas.billing_sequence_number >= xacl.initial_billing_sequence 
    AND   xas.invoice_number           = rct.trx_number
    AND   rct.customer_trx_id          = aps.customer_trx_id
    and   xas.invoice_created_flag     = 'Y' 
    AND   xas.auth_completed_flag      = 'B'
    AND   aps.STATUS                   = 'OP'
    ;
    
    lc_procedure_name    CONSTANT  VARCHAR2(61) := gc_package_name || '.' || 'process_adjustments';

    lt_parameters                  gt_input_parameters;

    lc_action                      VARCHAR2(1000);

    lc_error                       VARCHAR2(2000);
    
    lc_init_msg_list                VARCHAR2(1000);
    
    lc_commit_flag                  VARCHAR2(5)                                := 'F';
                                                                               
    lc_validation_level             NUMBER(4)                                  := fnd_api.g_valid_level_full;
    
    ln_msg_count                    NUMBER(4);
    
    lc_msg_data                     VARCHAR2(1000);
    
    lc_return_status                VARCHAR2(5);
    
    lr_adj_rec                      ar_adjustments%rowtype;
    
    lc_chk_approval_limits          VARCHAR2(5)                                := 'F';
                                                                               
    lc_check_amount                 VARCHAR2(5)                                := 'F';
                                                                               
    lc_move_deferred_tax           VARCHAR2(1)                                 := 'Y';
    
    ln_new_adjust_number           ar_adjustments.adjustment_number%TYPE;
    
    ln_new_adjust_id               ar_adjustments.adjustment_id%TYPE;
    
    lc_called_from                 VARCHAR2(25)                                := 'ADJ-API';
    
    ln_old_adjust_id               ar_adjustments.adjustment_id%TYPE;
        
    lr_invoice_header_info         ra_customer_trx_all%ROWTYPE;

    ln_invoice_total_amount_info   ra_customer_trx_lines_all.extended_amount%TYPE;
    
    lr_inv_pymt_sch_info           ar_payment_schedules_all%ROWTYPE;
    
    ln_activity_id                 ar_receivables_trx_all.receivables_trx_id%TYPE;
    
    lc_transaction                 VARCHAR2(5000);
     
    lt_translation_info            xx_fin_translatevalues%ROWTYPE;
    
    lc_adj_status                  ar_adjustments_all.status%TYPE;
       
    le_processing                  EXCEPTION;

  BEGIN

    entering_sub(p_procedure_name  => lc_procedure_name,
                 p_parameters      => lt_parameters);

    retcode := 0;

    /*****************
    * Get enable debug
    *****************/
    lc_action := 'Calling set_debug';
    
    set_debug(p_debug_flag => p_debug_flag);
    
    /************************************
    * Get receivable activity information
    ************************************/
    lc_action := 'Calling get_payment_sch_info';
    
    get_rec_activity_info(x_activity_id => ln_activity_id);
      
    /***********************************************
    *  Loop thru pending contracts/billing sequences
    ***********************************************/
    
    lc_action := 'Calling c_eligible_contracts cursor';
    
    FOR inv_adjustment_rec IN c_inv_adjustment
    LOOP

      BEGIN
  
        lr_invoice_header_info         := NULL;
        ln_invoice_total_amount_info   := NULL;
        lr_inv_pymt_sch_info           := NULL;
        ln_msg_count                   := NULL;
        lc_msg_data                    := NULL;
        lc_return_status               := NULL;
        lr_adj_rec                     := NULL;
        ln_new_adjust_number           := NULL;
        ln_new_adjust_id               := NULL;
    
        /************************************************************************
        * Keep track of the contract number and billing sequence being worked on.
        ************************************************************************/

        lc_transaction := 'Processing invoice number: ' || inv_adjustment_rec.trx_number;

        logit(p_message => 'Transaction: ' || lc_transaction,
            p_force   => TRUE);
        
        /************************
        * Get invoice information
        ************************/
        
        lc_action := 'Calling get_invoice_header_info';
        
        get_invoice_header_info(p_invoice_number      => inv_adjustment_rec.trx_number,
                                x_invoice_header_info => lr_invoice_header_info);
        
        /******************************
        * Get invoice total information
        ******************************/
        
        lc_action := 'Calling get_invoice_total_amount_info';
        
        get_invoice_total_amount_info(p_customer_trx_id           => lr_invoice_header_info.customer_trx_id,
                                      x_invoice_total_amount_info => ln_invoice_total_amount_info);
                                      
        /*****************************************
        * Get invoice payment schedule information
        *****************************************/
        lc_action := 'Calling get_payment_sch_info';
        
        get_payment_sch_info(p_cust_trx_id       => lr_invoice_header_info.customer_trx_id,
                             x_payment_sch_info  => lr_inv_pymt_sch_info);
        
        /**************************
        * Populate v_adj_rec record
        **************************/
        
        lc_action := 'populating adj_rec records';
        
        lr_adj_rec.customer_trx_id     := lr_invoice_header_info.customer_trx_id;
        lr_adj_rec.TYPE                :='INVOICE';
        lr_adj_rec.payment_schedule_id := lr_inv_pymt_sch_info.payment_schedule_id;
        lr_adj_rec.receivables_trx_id  := ln_activity_id;
        lr_adj_rec.amount              := -ln_invoice_total_amount_info;
        lr_adj_rec.apply_date          := TRUNC(SYSDATE);
        lr_adj_rec.gl_date             := TRUNC(SYSDATE);
        lr_adj_rec.created_from        := 'ADJ-API';
        
        lc_action := 'calling create_adjustment API';
        
        ar_adjust_pub.create_adjustment ( p_api_name             => 'AR_ADJUST_PUB'
                                        , p_api_version          => 1.0
                                        , p_init_msg_list        => lc_init_msg_list
                                        , p_commit_flag         => lc_commit_flag
                                        , p_validation_level     => lc_validation_level
                                        , p_msg_count            => ln_msg_count
                                        , p_msg_data             => lc_msg_data
                                        , p_return_status        => lc_return_status
                                        , p_adj_rec              => lr_adj_rec
                                        , p_chk_approval_limits  => lc_chk_approval_limits
                                        --, p_check_amount         => lc_check_amount
                                        --, p_move_deferred_tax    => lc_move_deferred_tax
                                        , p_new_adjust_number    => ln_new_adjust_number
                                        , p_new_adjust_id        => ln_new_adjust_id
                                        , p_called_from          => lc_called_from
                                        --, p_old_adjust_id        => ln_old_adjust_id
                                        );
                                        
        logit(p_message => 'CREATE_ADJUSTMENT API return status: ' || lc_return_status);
        
        /**********************
        * Get api error message
        **********************/
        
        IF lc_return_status != 'S'
        THEN
        
          lc_error :=    'Error while creating adjustment-';
        
          IF ln_msg_count = 1
          THEN
            lc_error :=    lc_error || lc_msg_data;
          ELSE
            FOR r IN 1 .. ln_msg_count
            LOOP
              lc_error := lc_error || ', ' || fnd_msg_pub.get(fnd_msg_pub.g_next, fnd_api.g_false);
            END LOOP;
          END IF;
          
          logit(p_message => 'CREATE_ADJUSTMENT API error message: ' || lc_error);

          RAISE le_processing;
                  
        END IF;
        
        IF ln_new_adjust_number IS NOT NULL
        THEN
        
          lc_return_status := NULL;
          ln_msg_count     := NULL;
          lc_msg_data      := NULL;
          lc_adj_status    := NULL;
                  
          BEGIN
            SELECT NVL(status,
                       'X')
            INTO   lc_adj_status
            FROM   ar_adjustments_all
            WHERE  adjustment_number = ln_new_adjust_number;
          
            IF lc_adj_status != 'A'
            THEN
                lc_action := 'calling approve_adjustment API';
                
                ar_adjust_pub.approve_adjustment(p_api_name                 => 'AR_ADJUST_PUB',
                                                 p_api_version              => 1.0,
                                                 p_msg_count                => ln_msg_count,
                                                 p_msg_data                 => lc_msg_data,
                                                 p_return_status            => lc_return_status,
                                                 p_adj_rec                  => NULL,
                                                 p_chk_approval_limits      => fnd_api.g_false,
                                                 p_old_adjust_id            => ln_new_adjust_id);
            END IF;
          EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
                
                logit(p_message => 'Error Getting Status for Adjustment:' || ln_new_adjust_number);
                
                RAISE le_processing;
          END;
          
          lc_error :=    'Error while approving adjustment-';
        
          /**********************
          * Get api error message
          **********************/
          
          IF lc_return_status != 'S'
          THEN
          
            lc_error :=    'Error while approving adjustment-';
          
            IF ln_msg_count = 1
            THEN
              lc_error :=    lc_error || lc_msg_data;
            ELSE
              FOR r IN 1 .. ln_msg_count
              LOOP
                lc_error := lc_error || ', ' || fnd_msg_pub.get(fnd_msg_pub.g_next, fnd_api.g_false);
              END LOOP;
            END IF;
            
            logit(p_message => 'APPROVE_ADJUSTMENT API error message: ' || lc_error);
          
            RAISE le_processing;
        
          END IF;
          
        END IF;
          
      EXCEPTION
        WHEN le_processing
        THEN
        
          errbuff := 'Error encountered. Please check logs';
        
          logit(p_message => 'ERROR Transaction: ' || lc_transaction || ' Action: ' || lc_action || ' SQLCODE: ' || SQLCODE || ' SQLERRM: ' || SQLERRM,
                p_force   => TRUE);
          logit(p_message      => '-----------------------------------------------',
                p_force   => TRUE);

        WHEN OTHERS
        THEN
        
          errbuff := 'Error encountered. Please check logs';
        
          logit(p_message => 'ERROR Transaction: ' || lc_transaction || ' Action: ' || lc_action || ' SQLCODE: ' || SQLCODE || ' SQLERRM: ' || SQLERRM,
                p_force   => TRUE);
          logit(p_message      => '-----------------------------------------------',
                p_force   => TRUE);

      END;
    
    END LOOP;

    exiting_sub(p_procedure_name => lc_procedure_name);

  EXCEPTION
    WHEN OTHERS
    THEN
      retcode := 2;
    
      errbuff := 'Error encountered. Please check logs';
    
      logit(p_message => 'ERROR Transaction: ' || lc_transaction || ' Action: ' || lc_action || ' SQLCODE: ' || SQLCODE || ' SQLERRM: ' || SQLERRM,
            p_force   => TRUE);
      logit(p_message      => '-----------------------------------------------',
            p_force   => TRUE);
    
      exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => TRUE);

  END process_adjustments;

/* **********************************************************************************************
 Procedure for B2B to create a new Order in AOPS for proposed Renewal of a contract (for Alt SKU)
************************************************************************************************ */
   PROCEDURE contract_autorenew_process(errbuff            OUT VARCHAR2,
                                       retcode            OUT NUMBER,
                                       p_debug_flag       IN  VARCHAR2 DEFAULT 'N'
                                      )
  IS

   CURSOR c_autorenew_contract_lines 
   IS    
    SELECT contract_id,contract_number,billing_sequence_number,notification_days,total_contract_amount,contract_line_number
     FROM
     (
         SELECT XACL.contract_id,XAC.contract_number,XAS.billing_sequence_number,0 notification_days,sum(xacl.contract_line_amount) total_contract_amount
               ,XAS.contract_line_number 
         FROM   xx_ar_contract_lines XACL,
                xx_ar_contracts XAC,
                xx_ar_subscriptions XAS
         WHERE  TRUNC(SYSDATE-1) = TRUNC(XACL.contract_line_end_date)
         AND    XACL.contract_id = XAC.contract_id
       --AND    XAC.contract_status = 'ACTIVE'
       --AND    XAC.external_source = 'POS'
         AND    XAC.contract_id = XAS.contract_id
         AND    XACL.alternative_sku IS NOT NULL
         AND    XACL.contract_line_number = XAS.contract_line_number
         AND    XACL.close_date IS NULL
         AND    XACL.cancellation_date IS NULL
         AND    XACL.program = 'SS'
         AND    NVL(XAS.AUTO_RENEWED_FLAG,'N') != 'Y'
         AND    XAS.billing_sequence_number IN (SELECT MAX(XAS1.billing_sequence_number) 
                                                FROM  xx_ar_subscriptions XAS1
                                                WHERE XAS1.contract_id = XAS.contract_id
                                                AND   XAS1.contract_line_number = XAS.contract_line_number
                                                )
         GROUP BY XACL.contract_id,XAC.contract_number,XAS.billing_sequence_number,0,XAS.contract_line_number                                                  
         UNION
         SELECT XACL.contract_id,XAC.contract_number,XAS.billing_sequence_number,0 notification_days,sum(xacl.contract_line_amount) total_contract_amount
               ,XAS.contract_line_number
         FROM   xx_ar_contract_lines XACL,
                xx_ar_contracts XAC,
                xx_ar_subscriptions XAS
         WHERE  TRUNC(SYSDATE-1) = TRUNC(XACL.contract_line_end_date)
         AND    XACL.contract_id = XAC.contract_id
       --AND    XAC.contract_status = 'ACTIVE'
       --AND    XAC.external_source = 'POS'
         AND    XAC.contract_id = XAS.contract_id
         AND    XACL.alternative_sku IS NOT NULL
         AND    XACL.contract_line_number = XAS.contract_line_number
         AND    XACL.cancellation_date IS NULL
         AND    XACL.close_date IS NULL
         AND    XACL.program ='BS'
         AND    NVL(XAS.AUTO_RENEWED_FLAG,'N') != 'Y'
         AND    XAS.billing_sequence_number IN (SELECT MAX(XAS1.billing_sequence_number)
                                                FROM  xx_ar_subscriptions XAS1
                                                WHERE XAS1.contract_id = XAS.contract_id
                                                AND   XAS1.contract_line_number = XAS.contract_line_number
                                                )
         GROUP BY XACL.contract_id,XAC.contract_number,XAS.billing_sequence_number,0,XAS.contract_line_number                                                  
     )
     GROUP BY contract_id,contract_number,billing_sequence_number,notification_days,total_contract_amount,contract_line_number
     ORDER BY contract_id ; 
     

    lc_procedure_name    CONSTANT  VARCHAR2(61) := gc_package_name || '.' || 'contract_autorenew_process';
    lt_program_setups              gt_translation_values;
    lt_parameters                  gt_input_parameters;
    lc_action                      VARCHAR2(1000);
    lc_error                       VARCHAR2(1000);
    ln_loop_counter                NUMBER := 0;
    lr_contract_info               xx_ar_contracts%ROWTYPE;
    lr_contract_line_info          xx_ar_contract_lines%ROWTYPE;
    lt_subscription_array          subscription_table;
    lc_wallet_id                   xx_ar_contracts.payment_identifier%TYPE;
    lc_masked_credit_card_number   xx_ar_subscriptions.settlement_cc_mask%TYPE;
    lc_b2b_renewal_payload         VARCHAR2(32000) := NULL;
    lc_card_expiration_date        VARCHAR2(4);
    lc_decrypted_value             xx_ar_contracts.card_token%TYPE;
    l_request                      UTL_HTTP.req;
    l_response                     UTL_HTTP.resp;
    lclob_buffer                   CLOB;
    lc_buffer                      VARCHAR2(10000);
    lr_subscription_payload_info   xx_ar_subscription_payloads%ROWTYPE;
    lr_subscription_error_info     xx_ar_subscriptions_error%ROWTYPE;
    lc_autorenew_sent_flag         VARCHAR2(2)  := 'N';
    lc_email_sent_counter          NUMBER := 0;
    lc_invoice_status              VARCHAR2(30)  := NULL;
    le_processing                  EXCEPTION;
    lr_order_header_info           oe_order_headers_all%ROWTYPE := NULL;
    lr_bill_to_cust_acct_site_info hz_cust_acct_sites_all%ROWTYPE := NULL;
    lr_customer_info               hz_cust_accounts%ROWTYPE;
    lr_ship_to_cust_acct_site_info hz_cust_acct_sites_all%ROWTYPE := NULL;
    lr_pos_ordt_info               xx_ar_order_receipt_dtl%ROWTYPE;
    lr_pos_info                    xx_ar_pos_inv_order_ref%ROWTYPE;
    lr_bill_to_seq                 VARCHAR2(10) :='';
    lr_ship_to_seq                 VARCHAR2(10) :='';
    lr_xx_od_oks_alt_sku_tbl       xx_od_oks_alt_sku_tbl%ROWTYPE;   

  BEGIN
    
    lt_parameters('p_debug_flag') := p_debug_flag;
    
    entering_main(p_procedure_name   => lc_procedure_name,
                  p_rice_identifier  => 'E7044',
                  p_debug_flag       => p_debug_flag,
                  p_parameters       => lt_parameters);
   

    /***************************************************************************************
    * Validate we have all the information in subscriptions needed to send the billing email
    ***************************************************************************************/

   /******************************
    * Initialize program variables.
    ******************************/

    retcode := 0;

    lc_action := 'Calling get_program_setups';

    get_program_setups(x_program_setups => lt_program_setups);

    /******************************
     *Loop thru eligible contracts
     ******************************/

        lc_action := 'Calling c_autorenew_contract_lines in contract_autorenew_process';

        FOR autorenew_contract_lines_rec IN c_autorenew_contract_lines
        LOOP
        
        BEGIN
       
      /*******************************************************
      * Validate we are ready to send the auto renewal email
      ********************************************************/

       /**************************************
        * Get contract header level information
        **************************************/

        lc_action := 'Calling get_contract_info in contract_autorenew_process';

        get_contract_info(p_contract_id     => autorenew_contract_lines_rec.contract_id,
                          x_contract_info   => lr_contract_info);

        /********************************************
        * Get all the associated subscription records
        ********************************************/

        lt_subscription_array.delete();

        lc_action := 'Calling get_subscription_array in contract_autorenew_process';

        get_alt_subscription_array(p_contract_id             => autorenew_contract_lines_rec.contract_id,
                                   p_line_number             => autorenew_contract_lines_rec.contract_line_number,
                                   p_billing_sequence_number => autorenew_contract_lines_rec.billing_sequence_number,
                                   x_subscription_array      => lt_subscription_array);

        ln_loop_counter := 0;

         /******************************
          * Get initial order header info
          ******************************/

          IF (lr_order_header_info.header_id IS NULL) 
          THEN
            lc_action := 'Calling get_order_header_info in contract_autorenew_process';

            IF lr_contract_info.external_source = 'POS'
            THEN
              get_pos_ordt_info(p_order_number => lr_contract_info.initial_order_number,
                    x_ordt_info    => lr_pos_ordt_info);
                    
              get_pos_info(p_header_id        => lr_pos_ordt_info.header_id, 
                           p_orig_sys_doc_ref => lr_contract_info.initial_order_number,
                           x_pos_info         => lr_pos_info);
                           
              get_order_header_info(p_order_number      => lr_contract_info.initial_order_number,
                                    x_order_header_info => lr_order_header_info);
            ELSE
              get_order_header_info(p_order_number      => lr_contract_info.initial_order_number,
                                    x_order_header_info => lr_order_header_info);
            END IF;
       
          END IF;
          
          /*************************************************
          * Get initial order BILL_TO cust account site info
          *************************************************/

          IF (lr_bill_to_cust_acct_site_info.cust_acct_site_id IS NULL)
          THEN
            lc_action := 'Calling get_cust_account_site_info for BILL_TO in contract_autorenew_process';
            
            IF lr_contract_info.external_source = 'POS'
            THEN
              get_customer_pos_info(p_aops           => lr_contract_info.bill_to_osr,
                                    x_customer_info  => lr_customer_info);
                                  
              get_cust_site_pos_info(p_customer_id     => lr_customer_info.cust_account_id,
                                     x_cust_site_info  => lr_bill_to_cust_acct_site_info);
            ELSE
              get_cust_account_site_info(p_site_use_id            => lr_order_header_info.invoice_to_org_id,
                                         p_site_use_code          => 'BILL_TO',
                                         x_cust_account_site_info => lr_bill_to_cust_acct_site_info);
            END IF;
            
            lr_bill_to_seq   := substr(lr_bill_to_cust_acct_site_info.orig_system_reference,length(lr_contract_info.bill_to_osr)+2,5);
         END IF;          
         IF (lr_ship_to_cust_acct_site_info.cust_acct_site_id IS NULL)
            THEN
              lc_action := 'Calling get_cust_account_site_info for SHIP_TO in contract_autorenew_process';
         
              IF lr_contract_info.external_source = 'POS'
              THEN
                get_customer_pos_info(p_aops           => lr_contract_info.bill_to_osr,
                                      x_customer_info  => lr_customer_info);
                                    
                get_cust_site_pos_info(p_customer_id     => lr_customer_info.cust_account_id,
                                       x_cust_site_info  => lr_ship_to_cust_acct_site_info);
              ELSE
                get_cust_account_site_info(p_site_use_id            => lr_order_header_info.ship_to_org_id,
                                           p_site_use_code          => 'SHIP_TO',
                                           x_cust_account_site_info => lr_ship_to_cust_acct_site_info);
              END IF;
          
          /* ************************************************
          * Get Complete Ship_To information
          *************************************************/
            lc_action := 'Get Complete Ship_To information in contract_autorenew_process';
            lr_ship_to_seq   := substr(lr_ship_to_cust_acct_site_info.orig_system_reference,length(lr_contract_info.bill_to_osr)+2,5);
            END IF;
           
      FOR indx IN 1 .. lt_subscription_array.COUNT
      LOOP
       
        BEGIN

          /* *****************************
          * Get contract line information
          ******************************/
          
          lc_action := 'Calling get_contract_line_info in contract_autorenew_process';
          
          get_contract_line_info(p_contract_id          => lt_subscription_array(indx).contract_id,
                                 p_contract_line_number => lt_subscription_array(indx).contract_line_number,
                                 x_contract_line_info   => lr_contract_line_info);
 
           /* *************************
            * GET ALTERNATE SKU DETAILS
            **************************/

            IF lr_contract_line_info.alternative_sku IS NOT NULL
            THEN

              lc_action := 'Getting alternate sku details in contract_autorenew_process';
              get_alternate_sku_info(p_item_name            =>  lr_contract_line_info.item_name,
                                     p_alternate_sku        =>  lr_contract_line_info.alternative_sku,
                                     x_alternate_sku_array  =>  lr_xx_od_oks_alt_sku_tbl);
            END IF;

          IF ln_loop_counter = 0
          THEN
              
            ln_loop_counter := ln_loop_counter + 1;  

            /***************************************
            * Masking card details except for PAYPAL
            ***************************************/
            lc_action := 'Masking credit card in contract_autorenew_process';

            IF lr_contract_info.card_type != 'PAYPAL'
            THEN
              
                /**************
                * Decrypt Value
                **************/
            
               BEGIN
                     lc_action := 'Calling decrypt_credit_card in contract_autorenew_process';
   
                     decrypt_credit_card(p_context_namespace => 'XX_AR_SUBSCRIPTIONS_MT_CTX',
                                         p_context_attribute => 'TYPE',
                                         p_context_value     => 'OM',
                                         p_module            => 'HVOP',
                                         p_format            => 'EBCDIC',
                                         p_encrypted_value   => lr_contract_info.card_token,
                                         p_key_label         => lr_contract_info.card_encryption_label,
                                         x_decrypted_value   => lc_decrypted_value);
                EXCEPTION
                     WHEN OTHERS THEN
                          lc_decrypted_value := 'INVALID CARD';
                          logit(p_message => 'Getting issue while calling decrypt credit card');
                END;
                       
              IF length(lc_decrypted_value)= 16 
                THEN
                 
                  lc_masked_credit_card_number :=  lc_decrypted_value;
                
                ELSIF lr_contract_info.payment_type = 'AB' THEN
                
                   lc_masked_credit_card_number:='';
                
                 ELSE
               
                  lc_masked_credit_card_number := 'BAD CARD '; 
                
                END IF;
              ELSE

               lc_masked_credit_card_number  :=     lr_contract_info.payment_identifier;

            END IF;

  
            /***********************
            * Format expiration date
            ***********************/

            IF lr_contract_info.card_expiration_date IS NOT NULL
            THEN

              lc_action := 'Formating card_expiration_date in contract_autorenew_process';

              lc_card_expiration_date := TO_CHAR(lr_contract_info.card_expiration_date, 'MMYY'); 

            END IF;
 
            /*******************************
            * Build auto renew process payload
            *******************************/
            lc_action := 'Building contract autorenewal process payload';
            SELECT  '{
                       "ODPurchaseOrder" : 
                        {
                         "@timeStamp" :"'
                              || TO_CHAR(SYSDATE,'YYYY-MON-DD HH24:MI:SS')
                              || '",
                         "@documentid" : "'
                              || lt_subscription_array(indx).contract_number
                              || '-'
                              || lr_contract_line_info.contract_line_number
                              ||'-'
                              || lt_subscription_array(indx).billing_sequence_number
                              || '",
                      "Header" : 
                       {
                         "Username" : "SUBRENEWAL",
                         "SalesAssociateID" : "'
                            || lr_contract_info.sales_representative
                            || '",
                         "LoyaltyID" :  "'
                            || lr_contract_info.loyalty_member_number
                            || '",
                         "CustomerID" : "'
                            || lr_contract_info.bill_to_osr
                            || '",
                      "ShipTo" : {
                               "@invLoc" : "'
                                     || substr(lr_contract_info.store_number,3)
                                     || '",
                                  "Addr" : {
                                 "@seq" : "'
                                || lr_ship_to_seq
                                || '",
                                 "Contact" : {
                                   "Name" : "'
                                              || lr_contract_info.bill_to_customer_name
                                              || '",
                                   "Email" : {
                                     "*body" : "'
                                                || lr_contract_info.customer_email
                                                || '"
                                   },
                                   "PhoneNumber" : {
                                     "Number" : " "
                                   }
                                 }
                               }
                             },
                    "BillTo" : 
                       {
                       "Addr" : 
                       {
                         "@seq" : "'
                        || lr_bill_to_seq
                        || '",
                        "@id" : "'
                        || lr_contract_info.bill_to_osr
                        || '"
                       }
                     }
                    },
             "Request" : 
                     {
                "OrderType" : "Order",                
                "OrderSource" : "'
                   || lr_contract_info.external_source
                   || '",
                "CustomerOrderNumber" : "'
                   || lr_contract_info.initial_order_number
                   || '",
                "OrderDate" : "'
                            || TO_CHAR(SYSDATE,'DD/MM/YYYY')
                            || '",
                 "Accounting": 
                          {
                            "CostCenter": "'
                             || lr_contract_line_info.cost_center
                             || '",
                            "Desktop": "'
                            || lr_contract_line_info.Desktop
                            || '",
                            "Release": "'
                            || lr_contract_line_info.release_num
                            || '",
                            "PONumber": 
                               {
                                "*body": "'
                               || lr_contract_line_info.purchase_order
                               || '"
                               }
                          },
                  "Payment" : 
                         {
                     "@method": "'
                             || DECODE(lr_contract_info.payment_type,'PAYPAL','PL','AB','AB','PLCC','CR','TK')
                             || '",
                     "CardNumber": "'
                             || lc_masked_credit_card_number
                             || '",
                     "AuthDate" : "'
                               || lt_subscription_array(indx).auth_datetime
                               || '",
                     "AuthBy" : "'
                          || lr_contract_info.cc_trans_id_source
                          || '",
                     "AuthRspCD" : "'
                          || lt_subscription_array(indx).auth_code
                          || '",
                     "AVSCode" : "'
                          || lt_subscription_array(indx).auth_avs_code
                          || '",
                     "ExpirationDate": "'
                             || lc_card_expiration_date--TO_CHAR(lr_contract_info.card_expiration_date,'MM/DD/YYYY')
                             || '",
                     "COFTranId" : "'||lr_contract_info.cc_trans_id
                          || '"
                    },
                  "Detail" : 
                   {
                     "Item" : 
                   [ 
                   {
                         "LineNumber" : "'
                             || lr_contract_line_info.contract_line_number
                             || '",
                         "Sku" : "'
                             || lr_contract_line_info.alternative_sku
                             || '",
                         "Description":"'
                             || lr_xx_od_oks_alt_sku_tbl.alt_desc
                             || '",
                         "Qty" : "'
                             || lr_contract_line_info.quantity
                             || '",
                         "UnitPrice" : "'
                             || (lr_xx_od_oks_alt_sku_tbl.altprice * 100)
                             || '",
                         "ContractNumber": "'
                             || lr_contract_info.contract_number
                             || '",
                         "Comments" : "",
                         "SubscriptionDetails" : 
                           {
                             "Frequency" : "'
                             || lr_xx_od_oks_alt_sku_tbl.altfreq
                             || '",
                             "IncentivePercent" : ""
                           }
                        } 
                       ]
                    }
             }
            }
        }'
            INTO   lc_b2b_renewal_payload
            FROM   DUAL;

            
            lc_action := 'Validating Wallet location';

            IF lt_program_setups('wallet_location') IS NOT NULL
            THEN

              lc_action := 'calling UTL_HTTP.set_wallet';

              UTL_HTTP.SET_WALLET(lt_program_setups('wallet_location'), lt_program_setups('wallet_password'));

            END IF;

            lc_action := 'Calling UTL_HTTP.set_response_error_check';

            UTL_HTTP.set_response_error_check(FALSE);

            lc_action := 'Calling UTL_HTTP.begin_request';

            l_request := UTL_HTTP.begin_request(lt_program_setups('b2b_order_creation'), 'POST', ' HTTP/1.1');

            lc_action := 'Calling UTL_HTTP.SET_HEADER: user-agent';

            UTL_HTTP.SET_HEADER(l_request, 'user-agent', 'mozilla/4.0');

            lc_action := 'Calling UTL_HTTP.SET_HEADER: content-type';

            UTL_HTTP.SET_HEADER(l_request, 'content-type', 'application/json');

            lc_action := 'Calling UTL_HTTP.SET_HEADER: Content-Length';

            UTL_HTTP.SET_HEADER(l_request, 'Content-Length', LENGTH(lc_b2b_renewal_payload));

            lc_action := 'Calling UTL_HTTP.SET_HEADER: Authorization';

            lc_action := 'Calling UTL_HTTP.write_text';

            UTL_HTTP.write_text(l_request, lc_b2b_renewal_payload);

            lc_action := 'Calling UTL_HTTP.get_response';

            l_response := UTL_HTTP.get_response(l_request);

            COMMIT;

            logit(p_message => 'Response status_code' || l_response.status_code);

            /*************************
            * Get response into a CLOB
            *************************/

            lc_action := 'Getting response';

            BEGIN

              lclob_buffer := EMPTY_CLOB;
              LOOP

                UTL_HTTP.read_text(l_response, lc_buffer, LENGTH(lc_buffer));
                lclob_buffer := lclob_buffer || lc_buffer;

              END LOOP;

              logit(p_message => 'Response Clob: ' || lclob_buffer);

              UTL_HTTP.end_response(l_response);

            EXCEPTION
              WHEN UTL_HTTP.end_of_body
              THEN

                UTL_HTTP.end_response(l_response);

            END;

            /***********************
            * Store request/response
            ***********************/

            lc_action := 'Store request/response';

            lr_subscription_payload_info.payload_id              := xx_ar_subscription_payloads_s.NEXTVAL;
            lr_subscription_payload_info.response_data           := lclob_buffer;
            lr_subscription_payload_info.creation_date           := SYSDATE;
            lr_subscription_payload_info.created_by              := FND_GLOBAL.USER_ID;
            lr_subscription_payload_info.last_updated_by         := FND_GLOBAL.USER_ID;
            lr_subscription_payload_info.last_update_date        := SYSDATE;
            lr_subscription_payload_info.input_payload           := lc_b2b_renewal_payload;
            lr_subscription_payload_info.contract_number         := lt_subscription_array(indx).contract_number;
            lr_subscription_payload_info.billing_sequence_number := lt_subscription_array(indx).billing_sequence_number;
            lr_subscription_payload_info.contract_line_number    := lt_subscription_array(indx).contract_line_number; --NULL;
            lr_subscription_payload_info.source                  := lc_procedure_name;

            lc_action := 'Calling insert_subscription_payload_info';

            insert_subscript_payload_info(p_subscription_payload_info => lr_subscription_payload_info);

            IF (l_response.status_code = 200)
            THEN

              lc_email_sent_counter := lc_email_sent_counter + 1;
 
              lt_subscription_array(indx).auto_renewed_flag  := 'Y';
              lt_subscription_array(indx).auto_renewed_date  := SYSDATE;
              lt_subscription_array(indx).last_update_date := SYSDATE;
              lt_subscription_array(indx).last_updated_by  := FND_GLOBAL.USER_ID;

            ELSE

              lc_action := NULL;

              lc_error  := 'Email sent failure - response code: ' || l_response.status_code;

              RAISE le_processing;

            END IF;

         ELSE
              lt_subscription_array(indx).auto_renewed_flag  := 'Y';
              lt_subscription_array(indx).auto_renewed_date  := SYSDATE;
              lt_subscription_array(indx).last_update_date := SYSDATE;
              lt_subscription_array(indx).last_updated_by  := FND_GLOBAL.USER_ID;
         END IF;--ln_loop_counter end if

         lc_action := 'Calling update_subscription_info';

        update_subscription_info(px_subscription_info => lt_subscription_array(indx));


      EXCEPTION
        WHEN le_processing
        THEN

          lr_subscription_error_info                         := NULL;
          lr_subscription_error_info.contract_id             := lt_subscription_array(indx).contract_id;
          lr_subscription_error_info.contract_number         := lt_subscription_array(indx).contract_number;
          lr_subscription_error_info.contract_line_number    := NULL;
          lr_subscription_error_info.billing_sequence_number := lt_subscription_array(indx).billing_sequence_number;
          lr_subscription_error_info.error_module            := lc_procedure_name;
          lr_subscription_error_info.error_message           := SUBSTR('Action: ' || lc_action || ' Error: ' || lc_error, 1, gc_max_err_size);
          lr_subscription_error_info.creation_date           := SYSDATE;

          lc_action := 'Calling insert_subscription_error_info';

          insert_subscription_error_info(p_subscription_error_info => lr_subscription_error_info);

          lc_autorenew_sent_flag := 'E';
          lc_error := SUBSTR(lr_subscription_error_info.error_message, 1, gc_max_sub_err_size);

          --RAISE le_processing;

        WHEN OTHERS
        THEN

          lr_subscription_error_info                         := NULL;
          lr_subscription_error_info.contract_id             := lt_subscription_array(indx).contract_id;
          lr_subscription_error_info.contract_number         := lt_subscription_array(indx).contract_number;
          lr_subscription_error_info.contract_line_number    := NULL;
          lr_subscription_error_info.billing_sequence_number := lt_subscription_array(indx).billing_sequence_number;
          lr_subscription_error_info.error_module            := lc_procedure_name;
          lr_subscription_error_info.error_message           := SUBSTR('Action: ' || lc_action || ' Error: ' || SQLCODE || ' ' || SQLERRM, 1, gc_max_err_size);
          lr_subscription_error_info.creation_date           := SYSDATE;

          lc_action := 'Calling insert_subscription_error_info';

          insert_subscription_error_info(p_subscription_error_info => lr_subscription_error_info);

          lc_autorenew_sent_flag := 'E';
          lc_error := SUBSTR(lr_subscription_error_info.error_message, 1, gc_max_sub_err_size);

          --RAISE le_processing;
         END;        
       END LOOP; -- indx IN 1 .. lt_subscription_array.COUNT
       --Setting the Variables NULL to reuse / next line
         lr_order_header_info :=NULL;
         lr_bill_to_cust_acct_site_info:=NULL;
         lr_ship_to_cust_acct_site_info:=NULL;
         lr_bill_to_seq:='';
         lr_ship_to_seq:='';

     EXCEPTION
      WHEN OTHERS
      THEN

      lr_subscription_error_info                         := NULL;
      lr_subscription_error_info.contract_id             := autorenew_contract_lines_rec.contract_id;
      lr_subscription_error_info.contract_number         := autorenew_contract_lines_rec.contract_number;
      lr_subscription_error_info.contract_line_number    := autorenew_contract_lines_rec.contract_line_number;
      lr_subscription_error_info.billing_sequence_number := autorenew_contract_lines_rec.billing_sequence_number;
      lr_subscription_error_info.error_module            := lc_procedure_name;
      lr_subscription_error_info.error_message           := SUBSTR('Action: ' || lc_action || ' Error: ' || SQLCODE || ' ' || SQLERRM, 1, gc_max_err_size);
      lr_subscription_error_info.creation_date           := SYSDATE;

      lc_action := 'Calling insert_subscription_error_info';

      insert_subscription_error_info(p_subscription_error_info => lr_subscription_error_info);

      lc_autorenew_sent_flag := 'E';
      lc_error := SUBSTR(lr_subscription_error_info.error_message, 1, gc_max_sub_err_size);
    END;

   END LOOP; --  autorenew_contract_lines_rec IN c_autorenew_contract_lines

    logit(p_message => 'Autorenewal EMAIL service executed successfully ' || lc_email_sent_counter || ' time.');

    exiting_sub(p_procedure_name => lc_procedure_name);

 EXCEPTION
      WHEN OTHERS THEN

      FOR indx IN 1 .. lt_subscription_array.COUNT
      LOOP

        lt_subscription_array(indx).auto_renewed_flag    := 'E';
        lt_subscription_array(indx).subscription_error := SUBSTR('Action: ' || lc_action || 'SQLCODE: ' || SQLCODE || ' SQLERRM: ' || SQLERRM, 1, gc_max_sub_err_size);

        lc_action := 'Calling update_subscription_info to update with error info';

        update_subscription_info(px_subscription_info => lt_subscription_array(indx));

      END LOOP;
      exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => TRUE);
      RAISE_APPLICATION_ERROR(-20101, 'PROCEDURE: ' || lc_procedure_name || ' Action: ' || lc_action || ' SQLCODE: ' || SQLCODE || ' SQLERRM: ' || SQLERRM);
  END contract_autorenew_process;
END xx_ar_subscriptions_mt_pkg;
/