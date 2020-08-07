SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY XX_GI_TO_AP_CONSIGN_LOAD_PKG
--Version Draft 1B
-- +=============================================================================+
-- |                  Office Depot - Project Simplify                            |
-- |                Oracle NAIO Consulting Organization                          |
-- +=============================================================================+
-- +=============================================================================+
-- |Package Name : XX_GI_TO_AP_CONSIGN_LOAD_PKG                                  |
-- |Purpose      : This package contains procedures that picks up the            |
-- |                consignment data from GL staging table(Custom) and transform |
-- |                it into consignment invoices to AP staging table(Custom).    |
-- |                                                                             |
-- |Tables Accessed :                                                            |
-- |Access Type----------------- (I - Insert, S - Select, U - Update, D - Delete)|
-- |                                                                             |
-- |XX_GI_TO_AP_STG              : S,U                                           |
-- |XX_AP_INV_INTERFACE_STG      : I                                             |
-- |XX_AP_INV_LINES_INTERFACE_STG: I                                             |
-- |XX_AP_INV_BATCH_INTERFACE_STG: I,U                                           | 
-- |HR_ORG_INFORMATION           : S                                             |
-- |PO_VENDOR_SITES_ALL          : S                                             |
-- |PO_VENDORS                   : S                                             |
-- |AP_TERMS                     : S                                             |
-- |                                                                             |
-- |Change History                                                               |
-- |                                                                             |
-- |Ver      Date          Author           Description                          |
-- |---      -----------   ---------------  -----------------------------        |
-- |Draft1A  16-Oct-2007   Arun Andavar     Draft version                        |
-- |Draft1B  24-Oct-2007   Arun Andavar     Removed pay group logic.             |
-- +=============================================================================+
IS
   -- ----------------------------------------
   -- Global constants used for error handling
   -- ----------------------------------------
   G_PROG_NAME                     CONSTANT VARCHAR2(50)  := 'XX_GI_TO_AP_CONSIGN_LOAD_PKG';
   G_MODULE_NAME                   CONSTANT VARCHAR2(50)  := 'INV';
   G_PROG_TYPE                     CONSTANT VARCHAR2(50)  := 'CUSTOM API';
   G_NOTIFY                        CONSTANT VARCHAR2(1)   := 'Y';
   G_MAJOR                         CONSTANT VARCHAR2(15)  := 'MAJOR';
   G_MINOR                         CONSTANT VARCHAR2(15)  := 'MINOR';
   G_989                           CONSTANT VARCHAR2(5)   := '-989';
   G_989_N                         CONSTANT PLS_INTEGER   := -989;
   G_APPL_PTP_SHORT_NAME           CONSTANT VARCHAR2(6)   := 'XXPTP';
   ------------------
   -- Other constants
   ------------------
   G_YES                           CONSTANT VARCHAR2(1)   := 'Y';
   G_NO                            CONSTANT VARCHAR2(1)   := 'N';
   G_ORG_INFO_CONTEXT              CONSTANT VARCHAR2(25)  := 'Accounting Information';
   G_WEEKLY_PAY_GROUP              CONSTANT VARCHAR2(20)  := 'US_OD_EXP_NON_DISC';
   G_DAILY_PAY_GROUP               CONSTANT VARCHAR2(20)  := 'US_OD_EXP_DISCOUNT';
   G_DAILY_TERMS                   CONSTANT VARCHAR2(3)   := '00';
   G_DAILY                         CONSTANT VARCHAR2(10)  := 'DAILY';
   G_WEEKLY                        CONSTANT VARCHAR2(10)  := 'WEEKLY';
   G_NUMBER_FORMAT                 CONSTANT VARCHAR2(15)  := '$9,999,999.99';
   G_INVOICE_SOURCE                CONSTANT VARCHAR2(25)  := 'US_OD_CONSIGNMENT_SALES';
   G_CONSIGN_CONVERSION            CONSTANT VARCHAR2(25)  := 'CONSIGN CONVERSION';
   G_CONSIGN_DECONVERSION          CONSTANT VARCHAR2(25)  := 'CONSIGN DECONVERSION';
   G_CONSIGN_CONSUMPTION           CONSTANT VARCHAR2(25)  := 'CONSIGN CONSUMPTION';
   G_TIME_FORMAT                   CONSTANT VARCHAR2(10)  := 'hh:mi:ss';
   G_PGM_STRT_END_FORMAT           CONSTANT VARCHAR2(25)  := 'DD-Mon-RRRR '||G_TIME_FORMAT||' AM';
   G_RICE_ID                       CONSTANT VARCHAR2(10)  := 'E0432';
   G_INVOICE_STANDARD              CONSTANT VARCHAR2(10)  := 'Standard';
   G_INVOICE_CREDIT_MEMO           CONSTANT VARCHAR2(11)  := 'Credit Memo';
   G_LINE_TYPE                     CONSTANT VARCHAR2(10)  := 'Item';
   G_DATE_FORMAT                   CONSTANT VARCHAR2(10)  := 'YYMMDD';
   G_ERROR_DATE_FORMAT             CONSTANT VARCHAR2(12)  := 'DD-Mon-RRRR';
   G_DAY                           CONSTANT VARCHAR2(10)  := 'SATURDAY';
   --------------------------
   -- Used for error handling
   --------------------------
   gc_error_message                VARCHAR2(5000)                                        := NULL;
   gc_error_code                   VARCHAR2(100)                                         := NULL;
   ---------
   -- Cursor
   ---------

   -- +========================================================================+
   -- | Name        :  LOG_ERROR                                               |
   -- |                                                                        |
   -- | Description :  This wrapper procedure calls the custom common error api|
   -- |                 with relevant parameters.                              |
   -- |                                                                        |
   -- | Parameters  :                                                          |
   -- |                p_exception IN VARCHAR2                                 |
   -- |                p_message   IN VARCHAR2                                 |
   -- |                p_code      IN PLS_INTEGER                              |
   -- |                                                                        |
   -- +========================================================================+
   PROCEDURE LOG_ERROR(p_exception IN VARCHAR2
                      ,p_message   IN VARCHAR2
                      ,p_code      IN PLS_INTEGER
                      )
   IS
      -------------------------
      -- Local scalar variables
      -------------------------
      lc_severity VARCHAR2(15) := NULL;
   BEGIN

      IF p_code = -1 THEN

         lc_severity := G_MAJOR;

      ELSIF p_code = 1 THEN

         lc_severity := G_MINOR;

      END IF;

      XX_COM_ERROR_LOG_PUB.LOG_ERROR
                           (
                            p_program_type            => G_PROG_TYPE     --IN VARCHAR2  DEFAULT NULL
                           ,p_program_name            => G_PROG_NAME     --IN VARCHAR2  DEFAULT NULL
                           ,p_module_name             => G_MODULE_NAME   --IN VARCHAR2  DEFAULT NULL
                           ,p_error_location          => p_exception     --IN VARCHAR2  DEFAULT NULL
                           ,p_error_message_code      => p_code          --IN VARCHAR2  DEFAULT NULL
                           ,p_error_message           => p_message       --IN VARCHAR2  DEFAULT NULL
                           ,p_error_message_severity  => lc_severity     --IN VARCHAR2  DEFAULT NULL
                           ,p_notify_flag             => G_NOTIFY        --IN VARHCAR2  DEFAULT NULL
                           );

   END LOG_ERROR;
-- +====================================================================+
-- | Name        :  get_fnd_message                                     |
-- | Description :  This function get the message after                 |
-- |                 substituting the tokens.                           |
-- | Parameters  :  p_name IN VARCHAR2                                  |
-- |                p_1    IN VARCHAR2 DEFAULT NULL                     |
-- |                p_v1   IN VARCHAR2 DEFAULT NULL                     |
-- |                p_2    IN VARCHAR2 DEFAULT NULL                     |
-- |                p_v2   IN VARCHAR2 DEFAULT NULL                     |
-- |                p_3    IN VARCHAR2 DEFAULT NULL                     |
-- |                p_v3   IN VARCHAR2 DEFAULT NULL                     |
-- +====================================================================+
FUNCTION get_fnd_message(
                         p_name IN VARCHAR2
                        ,p_1    IN VARCHAR2 DEFAULT NULL
                        ,p_v1   IN VARCHAR2 DEFAULT NULL
                        ,p_2    IN VARCHAR2 DEFAULT NULL
                        ,p_v2   IN VARCHAR2 DEFAULT NULL
                        ,p_3    IN VARCHAR2 DEFAULT NULL
                        ,p_v3   IN VARCHAR2 DEFAULT NULL
                        )
RETURN VARCHAR2
IS
BEGIN
   FND_MESSAGE.SET_NAME(G_APPL_PTP_SHORT_NAME,p_name);
   IF p_1 IS NOT NULL THEN
     FND_MESSAGE.SET_TOKEN(p_1,p_v1);
   END IF;
   IF p_2 IS NOT NULL THEN
      FND_MESSAGE.SET_TOKEN(p_2,p_v2);
   END IF;
   IF p_3 IS NOT NULL THEN
      FND_MESSAGE.SET_TOKEN(p_3,p_v3);
   END IF;
   RETURN FND_MESSAGE.GET;
END;
-- +====================================================================+
-- | Name        :  display_out                                         |
-- | Description :  This procedure is invoked to print in the out file  |
-- |                                                                    |
-- | Parameters  :  Output Message                                      |
-- +====================================================================+
PROCEDURE display_out(
                      p_message IN VARCHAR2
                     )
IS
BEGIN
     FND_FILE.PUT_LINE(FND_FILE.OUTPUT,p_message);
END;

-- +====================================================================+
-- | Name        :  display_log                                         |
-- | Description :  This procedure is invoked to print in the log file  |
-- |                                                                    |
-- | Parameters  :  Output Message                                      |
-- +====================================================================+
PROCEDURE display_log(
                      p_message IN VARCHAR2
                     )
IS
BEGIN
     FND_FILE.PUT_LINE(FND_FILE.LOG,p_message);
END;

-- +========================================================================+
-- | Name        :  TRANSFORM_TO_AP_INVOICE_STG                             |
-- |                                                                        |
-- | Description :  This procedure picks up the unprocessed inventory       |
-- |                 consignment data and transform it into AP consignment  |
-- |                 invoices and loads it into AP staging table.           |
-- |                                                                        |
-- | Parameters  :  p_daily_or_weekly      IN  VARCHAR2                     |
-- |                x_error_code           OUT PLS_INTEGER                  |
-- |                x_error_message        OUT VARCHAR2                     |
-- |                                                                        |
-- +========================================================================+
PROCEDURE TRANSFORM_TO_AP_INVOICE_STG(x_error_message        OUT VARCHAR2
                                     ,x_error_code           OUT PLS_INTEGER
                                     ,p_daily_or_weekly      IN  VARCHAR2
                                     )
IS
   ------------------
   -- Local constants
   ------------------
   --------------------------
   -- User defined exceptions
   --------------------------
   EX_VALIDATION_ERR   EXCEPTION;
   EX_ERR_BATCH_INSERT EXCEPTION;
   EX_ERR_BATCH_SEQ    EXCEPTION;
   EX_PRICE_QNTY_ERR   EXCEPTION;
   -------------------------
   -- Local scalar variables
   -------------------------
   lc_operating_unit           VARCHAR2(10)                 := NULL;
   lc_is_batchs_first_record   VARCHAR2(1)                  := NULL;
   lc_is_new_invoice           VARCHAR2(1)                  := NULL;
   ln_records_processed        PLS_INTEGER                  := NULL;
   lc_invoice_number           VARCHAR2(60)                 := NULL;
   lc_invoice_type_code        VARCHAR2(20)                 := NULL;
   lc_first_success_invoice    VARCHAR2(1)                  := NULL;
   ln_no_of_lines              PLS_INTEGER                  := NULL;
   lc_first_error_record       VARCHAR2(1)                  := NULL;
   lc_first_line_error         VARCHAR2(1)                  := NULL;
   ln_invoices_inserted        PLS_INTEGER                  := NULL;
   ln_invoice_details_inserted PLS_INTEGER                  := NULL;
   ln_total_batch_amount       PLS_INTEGER                  := NULL;
   ln_records_failed           PLS_INTEGER                  := NULL;
   ln_batch_id                 PLS_INTEGER                  := NULL;
   ln_invoice_id               PLS_INTEGER                  := NULL;
   lc_ou_name                  hr_operating_units.name%TYPE := NULL;
   lc_program_start_time       VARCHAR2(50)                 := NULL;
   lc_rowid                    ROWID                        := NULL;

   TYPE err_rowid_tbl_type IS TABLE OF ROWID
   INDEX BY BINARY_INTEGER;
   lt_err_row_id err_rowid_tbl_type;
   -------------------------------------------------------------
   -- Cursor to fetch all unprocessed inventory consignment data
   ------------------------------------------------------------- 
   CURSOR lcu_invoice_headers
   IS
   SELECT XGTAS.primary_supplier_site_id vendor_site_id
         ,XGTAS.invoice_type
         ,PV.SEGMENT1 vendor_number
         ,TO_CHAR(NEXT_DAY(TRUNC(XGTAS.mtl_transaction_date)
                          ,G_DAY
                          )
                 ,G_DATE_FORMAT
                 ) weekending_date
         ,COUNT(1) details_count
         ,SUM(po_cost * primary_quantity) total_invoice_amount
   FROM   xx_gi_to_ap_stg XGTAS
         ,po_vendor_sites_all PVSA
         ,po_vendors PV
   WHERE  
          (
              XGTAS.extract_date IS NULL
          AND TRUNC(XGTAS.mtl_transaction_date) <= TRUNC(SYSDATE)  
          AND p_daily_or_weekly                 = G_DAILY  
          AND PVSA.vendor_site_id                = XGTAS.primary_supplier_site_id 
          AND PVSA.vendor_id                     = PV.vendor_id 
          --AND PVSA.pay_group_lookup_code         = G_DAILY_PAY_GROUP
          AND PVSA.termS_id = (SELECT term_id
                               FROM   AP_TERMS
                               WHERE  NAME = G_DAILY_TERMS
                              ) 
         ) 
         OR 
         (
              XGTAS.extract_date IS NULL
          AND TRUNC(mtl_transaction_date) <= NEXT_DAY(TRUNC(SYSDATE)-8
                                                 ,G_DAY
                                                 )
          AND  p_daily_or_weekly = G_WEEKLY 
          AND  PVSA.vendor_site_id = XGTAS.primary_supplier_site_id 
          AND  PVSA.vendor_id      = PV.vendor_id 
          --AND  PVSA.pay_group_lookup_code = G_WEEKLY_PAY_GROUP 
          AND  PVSA.termS_id != (SELECT term_id 
                                 FROM AP_TERMS 
                                 WHERE NAME = G_DAILY_TERMS
                                 )
          )  
   GROUP BY XGTAS.primary_supplier_site_id
           ,XGTAS.invoice_type
           ,TO_CHAR(NEXT_DAY(TRUNC(XGTAS.mtl_transaction_date)
                           ,G_DAY
                      )
                   ,G_DATE_FORMAT
                   )
           ,PV.SEGMENT1
   ;
   -----------------------------------------
   -- To get all lines for the given invoice
   -----------------------------------------
   CURSOR lcu_invoice_lines(p_invoice_type IN VARCHAR2
                           ,p_vendor_site_id IN PLS_INTEGER)
   IS
   SELECT SUM(po_cost*primary_quantity) line_amount
         ,XGTAS.reference_account
         ,HOI.org_information3
   FROM   xx_gi_to_ap_stg XGTAS
         ,hr_organization_information HOI
   WHERE  XGTAS.invoice_type             = p_invoice_type
   AND    XGTAS.primary_supplier_site_id = p_vendor_site_id
   AND    HOI.organization_id            = XGTAS.organization_id
   AND    HOI.org_information3 IS NOT NULL
   AND    XGTAS.extract_date IS NULL
   GROUP BY 
          XGTAS.reference_account
         ,HOI.org_information3
   ;
   ------------------------------------------------------------------------
   -- Cursor to get the operating unit for the currently processing invoice
   ------------------------------------------------------------------------
   CURSOR lcu_get_operating_unit(p_invoice_type IN VARCHAR2
                                ,p_vendor_site_id IN PLS_INTEGER
                                )
   IS
   SELECT HOI.org_information3
         ,HOU.name
         ,ap_invoices_interface_s.NEXTVAL
   FROM   hr_organization_information HOI
         ,xx_gi_to_ap_stg             XGTAS
         ,hr_operating_units          HOU
   WHERE  HOI.org_information_context    = G_ORG_INFO_CONTEXT
   AND    XGTAS.invoice_type             = p_invoice_type
   AND    XGTAS.primary_supplier_site_id = p_vendor_site_id
   AND    HOI.organization_id            = XGTAS.organization_id
   AND    HOI.org_information3           = HOU.organization_id
   AND    HOI.org_information3           IS NOT NULL
   AND    XGTAS.extract_date             IS NULL
   AND    ROWNUM                         = 1
   ;
   --------------------------------------------------------------------------
   -- Cursor to check if any invoice lines exist with required column as null
   --  or values less than or equal to zero
   --------------------------------------------------------------------------
   CURSOR lcu_is_price_or_qnty_null(p_invoice_type IN VARCHAR2
                                   ,p_vendor_site_id IN PLS_INTEGER
                                   )
   IS
   SELECT XGTAS.ROWID
   FROM   xx_gi_to_ap_stg XGTAS
   WHERE  XGTAS.invoice_type             = p_invoice_type
   AND    XGTAS.extract_date IS NULL
   AND    XGTAS.primary_supplier_site_id = p_vendor_site_id
   AND    (XGTAS.po_cost IS NULL
           OR
           XGTAS.primary_quantity IS NULL
           OR
           XGTAS.primary_quantity <= 0
           OR
           XGTAS.po_cost <= 0
          )
   ;
   ----------------------------------------------------------------------------
   -- Cursor to get errored records for this batch to be printed on output file
   ----------------------------------------------------------------------------
   CURSOR lcu_errored_records(p_batch_id IN VARCHAR2)
   IS
   SELECT XGTAS.extract_error_explanation error_msg
         ,MMT.transaction_id
         ,MTT.transaction_type_name tipe
         ,MTR.reason_name           reason
         ,HAOU.name                 org_name
         ,MSIB.segment1             item_number
         ,TO_CHAR(XGTAS.mtl_transaction_date
                ,'DD-Mon-RRRR')     trans_date
         ,XGTAS.invoice_type
         ,XGTAS.primary_supplier_site_id vendor_site_id
   FROM   mtl_material_transactions MMT
         ,mtl_transaction_types     MTT
         ,mtl_transaction_reasons   MTR
         ,xx_gi_to_ap_stg           XGTAS
         ,hr_all_organization_units HAOU
         ,mtl_system_items_b        MSIB
   WHERE  MMT.transaction_id      (+)     = XGTAS.mtl_transaction_id
   AND    MTR.reason_id           (+)     = XGTAS.mtl_reason_id
   AND    MTT.transaction_type_id (+)     = XGTAS.mtl_transaction_type_id
   AND    HAOU.organization_id    (+)     = XGTAS.organization_id
   AND    MSIB.inventory_item_id  (+)     = XGTAS.inventory_item_id
   AND    MSIB.organization_id    (+)     = XGTAS.organization_id
   AND    XGTAS.extract_date              IS NULL
   AND    XGTAS.extract_error_explanation IS NOT NULL
   AND    XGTAS.batch_id = p_batch_id
   ;
BEGIN
   ---------------------------
   -- Initialize all variables
   ---------------------------
   lc_is_batchs_first_record   := G_YES;
   lc_first_success_invoice    := G_YES;
   gc_error_code               := NULL;
   gc_error_message            := NULL;
   ln_batch_id                 := NULL;
   lc_program_start_time       := TO_CHAR(SYSDATE,G_PGM_STRT_END_FORMAT);
   ln_records_processed        := 0;
   ln_invoices_inserted        := 0;
   ln_invoice_details_inserted := 0;
   ln_records_failed           := 0;
   ln_total_batch_amount       := 0;
   lc_is_new_invoice           := G_YES;
   lc_first_error_record       := G_YES;

   FOR lr_invoice_header IN lcu_invoice_headers
   LOOP
      BEGIN
         ln_invoice_id         := NULL;
         lc_invoice_number     := NULL;
         lc_invoice_type_code  := NULL;
         lc_ou_name            := NULL;

         IF lc_is_batchs_first_record = G_YES THEN

            lc_is_batchs_first_record := G_NO;
            --------------------------------------
            -- Write log/output header information
            --------------------------------------
            DISPLAY_LOG('Office Depot '||RPAD(' ',48,' ')||RPAD('Date: '||lc_program_start_time,29,' '));
            DISPLAY_LOG('Request ID: '||FND_GLOBAL.conc_request_id);
            DISPLAY_LOG(' ');
            DISPLAY_OUT('Office Depot '||RPAD(' ',48,' ')||RPAD('Date: '||lc_program_start_time,29,' '));
            DISPLAY_OUT('Request ID: '||FND_GLOBAL.conc_request_id);
            DISPLAY_OUT(' ');

            -----------------------------------------------
            -- Insert current batch information information
            -----------------------------------------------
            BEGIN
               SELECT xx_ap_inv_batch_intfc_stg_s.NEXTVAL
               INTO   ln_batch_id
               FROM   DUAL;
            EXCEPTION
               WHEN OTHERS THEN
                  gc_error_code    := SQLCODE;
                  FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62601_BATCH_SEQ_ERR');
                  FND_MESSAGE.SET_TOKEN('ORA_ERROR',SQLERRM);
                  gc_error_message := FND_MESSAGE.GET;
                  RAISE EX_ERR_BATCH_SEQ;
            END;
            DISPLAY_LOG('Batch ID: '||RPAD(ln_batch_id,16,' ')||RPAD('GI to AP Consignment Load Summary',61,' '));
            DISPLAY_LOG(' ');
            DISPLAY_OUT('Batch ID: '||RPAD(ln_batch_id,16,' ')||RPAD('GI to AP Consignment Load Statistics',61,' '));
            DISPLAY_OUT(' ');

            BEGIN

               INSERT INTO xx_ap_inv_batch_interface_stg
               (batch_id
               ,creation_date
               ,creation_time
               ,file_name
               )
               VALUES
               (ln_batch_id
               ,TRUNC(SYSDATE) 
               ,TO_CHAR(SYSDATE,G_TIME_FORMAT)
               ,G_RICE_ID
               );
            EXCEPTION
               WHEN OTHERS THEN
                  gc_error_code    := SQLCODE;

                  FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62602_BATCH_INS_ERR');
                  FND_MESSAGE.SET_TOKEN('ORA_ERROR',SQLERRM);

                  gc_error_message := FND_MESSAGE.GET;

                  RAISE EX_ERR_BATCH_INSERT;
            END;
            COMMIT;

         END IF;

         SAVEPOINT AFTER_BATCH_INSERT;

         ln_records_processed := ln_records_processed + lr_invoice_header.details_count;
         ---------------------------------------------
         -- Deriving invoice number, invoice type code
         ---------------------------------------------
         IF lr_invoice_header.invoice_type = G_CONSIGN_CONSUMPTION THEN

            IF p_daily_or_weekly = G_DAILY THEN

               lc_invoice_number := 'DAY'||TO_CHAR(SYSDATE,G_DATE_FORMAT);

            ELSE

               lc_invoice_number := 'WE'||lr_invoice_header.weekending_date;

            END IF;

            lc_invoice_type_code := G_INVOICE_STANDARD;

         ELSIF lr_invoice_header.invoice_type = G_CONSIGN_CONVERSION THEN

            lc_invoice_number := 'CBB'||TO_CHAR(SYSDATE,G_DATE_FORMAT)||lr_invoice_header.vendor_number;

            lc_invoice_type_code := G_INVOICE_CREDIT_MEMO;

         ELSIF lr_invoice_header.invoice_type = G_CONSIGN_DECONVERSION THEN

           lc_invoice_number := 'CBB'||TO_CHAR(SYSDATE,G_DATE_FORMAT)||lr_invoice_header.vendor_number;

           lc_invoice_type_code := G_INVOICE_STANDARD;

         ELSE

            FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62603_INVALID_INVC_TYPE');
            gc_error_message := FND_MESSAGE.GET;
            gc_error_code    := 'OD_INVALID_INVOICE_TYPE';

            RAISE EX_VALIDATION_ERR;

         END IF;
         ----------------------------------------------------------
         -- Derive operating unit only once for every invoice break
         ----------------------------------------------------------
         IF lc_is_new_invoice = G_YES then

            lc_operating_unit := NULL;

            lc_is_new_invoice := G_NO;

            OPEN lcu_get_operating_unit(lr_invoice_header.invoice_type
                                       ,lr_invoice_header.vendor_site_id
                                       );

            FETCH lcu_get_operating_unit INTO lc_operating_unit,lc_ou_name,ln_invoice_id;

            CLOSE lcu_get_operating_unit;

            IF lc_operating_unit IS NULL OR lc_ou_name IS NULL OR ln_invoice_id IS NULL THEN

               FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62608_OU_HDR_SEQ_ERR');

               gc_error_message := FND_MESSAGE.GET;
               gc_error_code := 'OD_OU_DERIVATION_ERROR';

               RAISE EX_VALIDATION_ERR;

            END IF;

         END IF;

         BEGIN

            INSERT INTO xx_ap_inv_interface_stg
            (invoice_id
            ,invoice_num
            ,invoice_type_lookup_code
            ,invoice_date
            ,vendor_site_id
            ,invoice_amount
            ,description
            ,source
            ,org_id
            ,last_update_date
            ,last_updated_by
            ,last_update_login
            ,creation_date
            ,created_by
            ,batch_id
             )
             VALUES
            (ln_invoice_id
            ,lc_invoice_number
            ,lc_invoice_type_code
            ,TRUNC(SYSDATE)
            ,lr_invoice_header.vendor_site_id
            ,ABS(lr_invoice_header.total_invoice_amount)
            ,lc_invoice_number
            ,G_INVOICE_SOURCE
            ,lc_operating_unit
            ,SYSDATE
            ,FND_GLOBAL.USER_ID
            ,FND_GLOBAL.LOGIN_ID
            ,SYSDATE
            ,FND_GLOBAL.USER_ID
            ,ln_batch_id
            );
         EXCEPTION
            WHEN OTHERS THEN
               gc_error_code    := SQLCODE;
               FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62604_INVC_HDR_INS_ERR');
               FND_MESSAGE.SET_TOKEN('ORA_ERROR',SQLERRM);
               gc_error_message := FND_MESSAGE.GET;
               RAISE EX_VALIDATION_ERR;
         END;
         ln_no_of_lines           := 0;
         lc_first_line_error      := G_YES;
         ------------------------------------------------------------------
         -- Check if for any of the existing line for the given invoice 
         --  PO_COST/PRIMARY_QUANTITY is null. If null then raise and error
         ------------------------------------------------------------------
         SELECT XGTAS.ROWID BULK COLLECT INTO lt_err_row_id
         FROM   xx_gi_to_ap_stg XGTAS
         WHERE  XGTAS.invoice_type             = lr_invoice_header.invoice_type
         AND    XGTAS.extract_date IS NULL
         AND    XGTAS.primary_supplier_site_id = lr_invoice_header.vendor_site_id
         AND    (XGTAS.po_cost IS NULL
                 OR
                 XGTAS.primary_quantity IS NULL
                 OR
                 XGTAS.primary_quantity <= 0
                 OR
                 XGTAS.po_cost <= 0
                )
         ;
         IF lt_err_row_id.COUNT > 0 THEN

            FOR i IN lt_err_row_id.FIRST..lt_err_row_id.LAST
            LOOP

               IF lc_first_line_error = G_YES THEN

                  ROLLBACK TO AFTER_BATCH_INSERT;
                  FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62605_PRICE_QNTY_ERR');
                  gc_error_message    := FND_MESSAGE.GET;
                  gc_error_code       := 'OD_LINE_LEVEL_PRICE_OR_QNTY_ERROR';

                  lc_first_line_error := G_NO;

               END IF;

               UPDATE XX_GI_TO_AP_STG
               SET    batch_id                  = ln_batch_id
                     ,extract_error_code        = gc_error_code
                     ,extract_error_explanation = gc_error_message
                     ,invoice_num               = NULL
                     ,invoice_id                = NULL
               WHERE  ROWID = lt_err_row_id(i)
               ;

            END LOOP;

         END IF;

         IF lc_first_line_error = G_NO THEN
            RAISE EX_PRICE_QNTY_ERR;
         END IF;

         FOR lr_invoice_lines IN lcu_invoice_lines(lr_invoice_header.invoice_type
                                                  ,lr_invoice_header.vendor_site_id
                                                  )
         LOOP

            ln_no_of_lines    := ln_no_of_lines + 1;

            BEGIN
               INSERT INTO xx_ap_inv_lines_interface_stg
               (invoice_id
               ,invoice_line_id
               ,line_number
               ,line_type_lookup_code
               ,amount
               ,dist_code_combination_id
               ,last_update_date
               ,last_updated_by
               ,last_update_login
               ,creation_date
               ,created_by
               )
               VALUES
               (ln_invoice_id
               ,ap_invoice_lines_interface_s.NEXTVAL
               ,ln_no_of_lines
               ,G_LINE_TYPE
               , lr_invoice_lines.line_amount
               , lr_invoice_lines.reference_account
               ,SYSDATE
               ,FND_GLOBAL.USER_ID
               ,FND_GLOBAL.LOGIN_ID
               ,SYSDATE
               ,FND_GLOBAL.USER_ID
               );

            EXCEPTION
               WHEN OTHERS THEN
                  gc_error_code    := SQLCODE;
                  FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62606_INVC_LINE_INS_ERR');
                  FND_MESSAGE.SET_TOKEN('ORA_ERROR',SQLERRM);
                  gc_error_message := FND_MESSAGE.GET;
                  RAISE EX_VALIDATION_ERR;
            END;

         END LOOP;

        ln_invoices_inserted        := ln_invoices_inserted + 1;

        ln_invoice_details_inserted := ln_invoice_details_inserted + ln_no_of_lines;

        ln_total_batch_amount       := ln_total_batch_amount + lr_invoice_header.total_invoice_amount;
        ----------------------------------------------------------------
        -- Update the extract date with sysdate in XX_GI_TO_AP_STG table
        ----------------------------------------------------------------
        UPDATE XX_GI_TO_AP_STG
        SET    extract_date             = SYSDATE
              ,invoice_num              = lc_invoice_number
              ,batch_id                 = ln_batch_id
              ,invoice_id               = ln_invoice_id
        WHERE  invoice_type             = lr_invoice_header.invoice_type
        AND    primary_supplier_site_id = lr_invoice_header.vendor_site_id
        ;

        lc_is_new_invoice := G_YES;

        IF lc_first_success_invoice = G_YES THEN

           -------------------------------------------------
           -- Write the invoice information in the log file.
           -------------------------------------------------
           lc_first_success_invoice := G_NO;
            DISPLAY_LOG(RPAD('Invoice ID',10,' ')     ||' '||
                        RPAD('Invoice Number',19,' ') ||' '||
                        RPAD('Invoice Type',20,' ')   ||' '||
                        RPAD('Invoice Date',12,' ')   ||' '||
                        RPAD('Invoice Amount',14,' ') ||' '||
                        RPAD('Supplier Site',13,' ')  ||' '||
                        RPAD('Operating Unit',14,' '));

            DISPLAY_LOG(RPAD('=',10,'=')||' '||
                        RPAD('=',19,'=')||' '||
                        RPAD('=',20,'=')||' '||
                        RPAD('=',12,'=')||' '||
                        RPAD('=',14,'=')||' '||
                        RPAD('=',13,'=')||' '||
                        RPAD('=',14,'='));

        END IF;

        DISPLAY_LOG(RPAD(ln_invoice_id,10,' ')                                                    ||' '||
                    RPAD(lc_invoice_number,19,' ')                                                ||' '||
                    RPAD(lr_invoice_header.invoice_type,20,' ')                                   ||' '||
                    RPAD(TO_CHAR(SYSDATE,'DD-MM-RRRR'),12,' ')                                    ||' '||
                    RPAD(TO_CHAR (lr_invoice_header.total_invoice_amount,G_NUMBER_FORMAT),14,' ')||' '||
                    RPAD(lr_invoice_header.vendor_site_id,13,' ')                                                  ||' '||
                    lc_ou_name);


        COMMIT;

      EXCEPTION
        WHEN EX_VALIDATION_ERR THEN

           ln_records_failed := ln_records_failed  + lr_invoice_header.details_count;
           x_error_code      := 1; 
           lc_is_new_invoice := G_YES;


           ROLLBACK TO AFTER_BATCH_INSERT;

           -- update error information in the XX_GI_TO_AP_STG table with batch id. Leave extract_date as null
           UPDATE XX_GI_TO_AP_STG 
           SET    extract_date              = NULL
                 ,extract_error_code        = gc_error_code
                 ,extract_error_explanation = gc_error_message
                 ,invoice_num               = NULL
                 ,batch_id                  = ln_batch_id
                 ,invoice_id                = NULL
           WHERE  invoice_type              = lr_invoice_header.invoice_type
           AND    primary_supplier_site_id  = lr_invoice_header.vendor_site_id
           ;

           LOG_ERROR(p_exception => gc_error_code    --IN VARCHAR2
                    ,p_message   => gc_error_message --IN VARCHAR2
                    ,p_code      => -1               --IN PLS_INTEGER
                    );

           COMMIT;
         WHEN EX_PRICE_QNTY_ERR THEN
            ln_records_failed := ln_records_failed  + lr_invoice_header.details_count;
            x_error_code      := 1; 
            lc_is_new_invoice := G_YES;

            LOG_ERROR(p_exception => gc_error_code    --IN VARCHAR2
                     ,p_message   => gc_error_message --IN VARCHAR2
                     ,p_code      => -1               --IN PLS_INTEGER
                     );

            COMMIT;
      END;
   END LOOP;
   -- Write into Output file
   -- Statistics

   DISPLAY_OUT(RPAD('Program Start Time: ',38,' ')||lc_program_start_time);
   DISPLAY_OUT(' ');
   DISPLAY_OUT(RPAD('No of records processed: ',38,' ')||ln_records_processed);
   DISPLAY_OUT('No of invoices inserted successfully: '||ln_invoices_inserted);
   DISPLAY_OUT('No of details  inserted successfully: '||ln_invoice_details_inserted);
   DISPLAY_OUT(RPAD('No of records failed: ',38,' ')||ln_records_failed);
   DISPLAY_OUT(' ');
   DISPLAY_OUT(RPAD('Program End Time:',38,' ')||TO_CHAR(SYSDATE,G_PGM_STRT_END_FORMAT));
   
   UPDATE xx_ap_inv_batch_interface_stg
   SET    invoice_count      = ln_invoices_inserted
         ,total_batch_amount = ln_total_batch_amount
   WHERE  batch_id = ln_batch_id
   ;

   FOR lr_err_recs IN lcu_errored_records(ln_batch_id)
   LOOP
      IF lc_first_error_record = G_YES THEN

         lc_first_error_record := G_NO;

         DISPLAY_OUT(' ');
         DISPLAY_OUT(' ');
         DISPLAY_OUT('Error Report: ');
         DISPLAY_OUT('============= ');
         DISPLAY_OUT(' ');
         DISPLAY_OUT(' ');
         DISPLAY_OUT(RPAD('Transaction ID',14,' ')       ||' '||
                     RPAD('Transaction Type',40,' ')     ||' '||
                     RPAD('Date',11,' ')                 ||' '||
                     RPAD('Transaction Reason',30,' ')   ||' '||
                     RPAD('Invoice Type',20,' ')         ||' '||
                     RPAD('Item Number',24,' ')          ||' '||
                     RPAD('Organization Name',42,' ')    ||' '||
                     RPAD('Supplier Site',13,' ')        ||' '||
                     RPAD('Error Message',50,' '));

         DISPLAY_OUT(RPAD('=',14,'=')||' '||
                     RPAD('=',40,'=')||' '||
                     RPAD('=',11,'=')||' '||
                     RPAD('=',30,'=')||' '||
                     RPAD('=',20,'=')||' '||
                     RPAD('=',24,'=')||' '||
                     RPAD('=',42,'=')||' '||
                     RPAD('=',13,'=')||' '||
                     RPAD('=',50,'=')
                     );

      END IF;

         DISPLAY_OUT(RPAD(lr_err_recs.transaction_id,14,' ')||' '||
                     RPAD(lr_err_recs.tipe,40,' ')          ||' '||
                     RPAD(lr_err_recs.trans_date,11,' ')    ||' '||
                     RPAD(lr_err_recs.reason,30,' ')        ||' '||
                     RPAD(lr_err_recs.invoice_type,20,' ')  ||' '||
                     RPAD(lr_err_recs.item_number,24,' ')   ||' '||
                     RPAD(lr_err_recs.org_name,42,' ')      ||' '||
                     RPAD(lr_err_recs.vendor_site_id,13,' ')||' '||
                     lr_err_recs.error_msg
                     );
   END LOOP;

   IF ln_records_processed = ln_records_failed THEN

      DISPLAY_LOG(' ');
      FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62609_ERROR_CONDITION');
      DISPLAY_LOG(FND_MESSAGE.GET);
      DISPLAY_LOG(' ');
      x_error_code := 2;

   END IF;

EXCEPTION
   WHEN EX_ERR_BATCH_SEQ THEN
      LOG_ERROR(p_exception => 'EX_ERR_BATCH_SEQ'     --IN VARCHAR2
               ,p_message   => gc_error_message       --IN VARCHAR2
               ,p_code      => -1                     --IN PLS_INTEGER
               );

      DISPLAY_LOG(' ');
      DISPLAY_LOG(gc_error_message);

      x_error_code := 2;
   WHEN EX_ERR_BATCH_INSERT THEN

      ROLLBACK;

      LOG_ERROR(p_exception => 'EX_ERR_BATCH_INSERT'  --IN VARCHAR2
               ,p_message   => gc_error_message       --IN VARCHAR2
               ,p_code      => -1                     --IN PLS_INTEGER
               );

      DISPLAY_LOG(' ');
      DISPLAY_LOG(gc_error_message);

      x_error_code := 2;
   WHEN OTHERS THEN

      IF lcu_invoice_lines%ISOPEN THEN
         CLOSE lcu_invoice_lines;
      END IF;
      IF lcu_is_price_or_qnty_null%ISOPEN THEN
         CLOSE lcu_is_price_or_qnty_null;
      END IF;
      IF lcu_get_operating_unit%ISOPEN THEN
         CLOSE lcu_get_operating_unit;
      END IF;
      IF lcu_invoice_headers%ISOPEN THEN
         CLOSE lcu_invoice_headers;
      END IF;

      DISPLAY_LOG(' ');

      FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62607_UNEXPECTED_ERR');
      FND_MESSAGE.SET_TOKEN('ORA_ERROR',SQLERRM);
      gc_error_message := FND_MESSAGE.GET;

      DISPLAY_LOG(gc_error_message);

      ROLLBACK;
      LOG_ERROR(p_exception => 'OTHERS'         --IN VARCHAR2
               ,p_message   => gc_error_message --IN VARCHAR2
               ,p_code      => -1               --IN PLS_INTEGER
               );
      x_error_code := 2;
END TRANSFORM_TO_AP_INVOICE_STG;


END XX_GI_TO_AP_CONSIGN_LOAD_PKG;
/
SHOW ERRORS;
EXIT;