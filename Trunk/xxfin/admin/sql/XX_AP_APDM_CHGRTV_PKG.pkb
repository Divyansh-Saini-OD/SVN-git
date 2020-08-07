SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating PACKAGE BODY XX_AP_APDM_CHGRTV_PKG

PROMPT Program exits IF the creation IS NOT SUCCESSFUL

WHENEVER SQLERROR CONTINUE

CREATE OR REPLACE PACKAGE BODY XX_AP_APDM_CHGRTV_PKG
AS
-- +==========================================================================+
-- |                  Office Depot - Project Simplify                         |
-- |                       WIPRO Technologies                                 |
-- +==========================================================================+
-- | Name     :   APDM Report                                                 |
-- | Rice id  :   R1050                                                       |
-- | Description : Checks if the data is available and to submit              |
-- |               the APDM concurrent program to get output                  |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version   Date              Author              Remarks                   |
-- |======   ==========     =============        =======================      |
-- |1.0       25-JUL-2007   Sambasiva Reddy D     Initial version             |
-- |                        Wipro Technologies                                |
-- |1.1       25-oct-2007   Sambasiva Reddy D     Change Request :            |
-- |                                              Changed CREDIT as Invoice   |
-- |                                              type lookup code for        |
-- |                                              defect 2389                 |
-- +==========================================================================+

-- +==========================================================================+
-- | Name : APDMREP                                                           |
-- | Description : Checks if the data is available and to submit              |
-- |               the APDM concurrent program to get output                  |
-- |                                                                          |
-- | Parameters : None                                                        |
-- |                                                                          |
-- |   Returns :    x_error_buff,x_ret_code                                   |
-- +==========================================================================+

PROCEDURE APDMREP(
                  x_error_buff          OUT  VARCHAR2
                 ,x_ret_code            OUT  NUMBER
                 )
AS

ln_checkrun_from              ap_checks_all.checkrun_id%TYPE;
ln_checkrun_to                ap_checks_all.checkrun_id%TYPE;
ln_conc_request_id            NUMBER;
ln_count                      NUMBER;
lc_error_loc                  VARCHAR2(4000);
lc_error_debug                VARCHAR2(4000);
lc_concurrent_program_name    fnd_concurrent_programs_tl.user_concurrent_program_name%TYPE;


BEGIN

            --To Get the  Concurrent Program Name
   lc_error_loc   := 'Get the Concurrent Program Name:';
   lc_error_debug := 'Concurrent Program id: '||FND_GLOBAL.CONC_PROGRAM_ID;

   SELECT   user_concurrent_program_name
   INTO     lc_concurrent_program_name
   FROM     fnd_concurrent_programs_tl
   WHERE    concurrent_program_id = FND_GLOBAL.CONC_PROGRAM_ID
   AND      language = USERENV('LANG');


     --   For ChargeBack Report
      BEGIN

         lc_error_loc   := 'Check the Chargeback CreditMemos available after last Successfull Run of the OD: Chargeback APDM Report';
         lc_error_debug := ' ';

         SELECT COUNT(1)
         INTO   ln_count
         FROM   ap_checks_all  APC
               ,ap_invoice_payments_all AIP
               ,ap_invoices_all AI
               ,fnd_lookup_values_vl FLV
         WHERE  TRUNC(APC.last_update_date) = TRUNC(SYSDATE-1)
         AND    APC.payment_method_lookup_code = 'CHECK'
         AND    APC.check_id  = AIP.check_id
         AND    AI.invoice_id = AIP.invoice_id
         AND    AI.attribute12 = 'Y'
       --AND    UPPER(AI.invoice_type_lookup_code) = 'DEBIT'      --Changed for defect 2389
         AND    AI.invoice_type_lookup_code = 'CREDIT'
         AND    AI.pay_group_lookup_code = FLV.lookup_code
         AND    FLV.lookup_type ='APCHARGEBACK_PAYGROUP'
         AND    TRUNC(NVL(FLV.end_date_active,SYSDATE+1)) > TRUNC(SYSDATE);

         IF (ln_count > 0) THEN

            FND_FILE.PUT_LINE(FND_FILE.LOG,'Number of CreditMemo records for Chargeback : ' ||ln_count);

               BEGIN

                  lc_error_loc   := 'Get the maximam and minimum Check run ID for Chargeback CreditMemos after last Successfull Run of the OD: Chargeback APDM Report';
                  lc_error_debug := ' ';

                  SELECT MIN(APC.checkrun_id)
                        ,MAX(APC.checkrun_id)
                  INTO   ln_checkrun_from
                        ,ln_checkrun_to
                  FROM   ap_checks_all  APC
                        ,ap_invoice_payments_all AIP
                        ,ap_invoices_all AI
                        ,fnd_lookup_values_vl FLV
                  WHERE  TRUNC(APC.last_update_date) =  TRUNC(SYSDATE-1)
                  AND    APC.payment_method_lookup_code = 'CHECK'
                  AND    APC.check_id  = AIP.check_id
                  AND    AI.invoice_id = AIP.invoice_id
                  AND    AI.attribute12 = 'Y'
                --AND    UPPER(AI.invoice_type_lookup_code) = 'DEBIT'       --Changed for defect 2389
                  AND    UPPER(AI.invoice_type_lookup_code) = 'CREDIT'
                  AND    AI.pay_group_lookup_code = FLV.lookup_code
                  AND    FLV.lookup_type ='APCHARGEBACK_PAYGROUP'
                  AND    TRUNC(NVL(FLV.end_date_active,SYSDATE+1)) > TRUNC(SYSDATE);

               EXCEPTION

                  WHEN OTHERS THEN
                     FND_FILE.PUT_LINE(FND_FILE.LOG,SQLERRM ||' - '|| lc_error_loc);

                     XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                               p_program_type            => 'CONCURRENT PROGRAM'
                              ,p_program_name            => lc_concurrent_program_name
                              ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                              ,p_module_name             => 'AP'
                              ,p_error_location          => 'Error at ' || lc_error_loc
                              ,p_error_message_count     => 1
                              ,p_error_message_code      => 'E'
                              ,p_error_message           => SQLERRM
                              ,p_error_message_severity  => 'Major'
                              ,p_notify_flag             => 'N'
                              ,p_object_type             => 'APDM CreditMemo for Chargeback'
                                                     );
               END;

            FND_FILE.PUT_LINE(FND_FILE.LOG,'Starting Checkrun Id for Chargeback:' ||ln_checkrun_from );
            FND_FILE.PUT_LINE(FND_FILE.LOG,'Ending Checkrun Id for Chargeback  :' ||ln_checkrun_to );

            ln_conc_request_id := fnd_request.submit_request(
                                                             'xxfin'
                                                            ,'XXAPCHBKAPDM'
                                                            ,NULL
                                                            ,NULL
                                                            ,NULL
                                                            ,ln_checkrun_from
                                                            ,ln_checkrun_to
                                                            );

            FND_FILE.PUT_LINE(FND_FILE.LOG,' Request ID - Chargeback : ' ||ln_conc_request_id );

         ELSE

            FND_FILE.PUT_LINE(FND_FILE.LOG,'No Data Found For Chargeback');

         END IF;

      EXCEPTION

         WHEN OTHERS THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG,'In Others of Chargeback ');
            FND_FILE.PUT_LINE(FND_FILE.LOG,SQLERRM ||' - '|| lc_error_loc);

            XX_COM_ERROR_LOG_PUB.LOG_ERROR (
            p_program_type            => 'CONCURRENT PROGRAM'
           ,p_program_name            => lc_concurrent_program_name
           ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
           ,p_module_name             => 'AP'
           ,p_error_location          => 'Error at ' || lc_error_loc
           ,p_error_message_count     => 1
           ,p_error_message_code      => 'E'
           ,p_error_message           => SQLERRM
           ,p_error_message_severity  => 'Major'
           ,p_notify_flag             => 'N'
           ,p_object_type             => 'APDM CreditMemo for Chargeback'
                                        );
      END;


     --   For RTV Report
      BEGIN

         lc_error_loc   := 'Check the RTV CreditMemos available after last Successfull Run of the OD: RTV APDM Report';
         lc_error_debug := ' ';

         SELECT COUNT(1)
         INTO   ln_count
         FROM   ap_checks_all  APC
               ,ap_invoice_payments_all AIP
               ,ap_invoices_all AI
               ,xx_fin_translatedefinition DEF
               ,xx_fin_translatevalues VAL
         WHERE  TRUNC(APC.last_update_date) =  TRUNC(SYSDATE-1)
         AND    APC.payment_method_lookup_code = 'CHECK'
         AND    APC.check_id = AIP.check_id
         AND    AI.invoice_id = AIP.invoice_id
       --AND    UPPER(AI.source) IN ('RTV','RCI')    --Changed to take source from Translation form
         AND    AI.invoice_num LIKE 'RTV%'
         AND    AI.SOURCE LIKE '%RTV%'
         AND    VAL.target_value1=AI.SOURCE
         AND    DEF.translate_id = VAL.translate_id
         AND    DEF.translation_name = 'AP_INVOICE_SOURCE'
       --AND    UPPER(AI.invoice_type_lookup_code) = 'DEBIT'       --Added for defect 2389
         AND    AI.invoice_type_lookup_code = 'CREDIT';

         IF (ln_count > 0) THEN

            FND_FILE.PUT_LINE(FND_FILE.LOG,'Number of CreditMemo records for RTV : '||ln_count);

            BEGIN

               lc_error_loc   := 'Get the maximam and minimum Check run ID for RTV CreditMemos after last Successfull Run of the OD: RTV APDM Report';
               lc_error_debug := ' ';

                  SELECT  MIN(APC.checkrun_id)
                         ,MAX(APC.checkrun_id)
                  INTO    ln_checkrun_from
                         ,ln_checkrun_to
                  FROM    ap_checks_all  APC
                         ,ap_invoice_payments_all AIP
                         ,ap_invoices_all AI
                         ,xx_fin_translatedefinition DEF
                         ,xx_fin_translatevalues VAL
                  WHERE   TRUNC(APC.last_update_date) =  TRUNC(SYSDATE-1)
                  AND     APC.payment_method_lookup_code = 'CHECK'
                  AND     APC.check_id  = AIP.check_id
                  AND     AI.invoice_id = AIP.invoice_id
                --AND     UPPER(AI.source) IN ('RTV','RCI')    --Changed to take source from Translation form
                  AND    AI.invoice_num LIKE 'RTV%'
                  AND    AI.SOURCE LIKE '%RTV%'
                  AND    VAL.target_value1=AI.SOURCE
                  AND    DEF.translate_id = VAL.translate_id
                  AND    DEF.translation_name = 'AP_INVOICE_SOURCE'
                --AND    UPPER(AI.invoice_type_lookup_code) = 'DEBIT'        --Added for defect 2389
                  AND    AI.invoice_type_lookup_code = 'CREDIT';

            EXCEPTION

               WHEN OTHERS THEN
                  FND_FILE.PUT_LINE(FND_FILE.LOG,SQLERRM ||' - '|| lc_error_loc);
                  XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                             p_program_type            => 'CONCURRENT PROGRAM'
                            ,p_program_name            => lc_concurrent_program_name
                            ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                            ,p_module_name             => 'AP'
                            ,p_error_location          => 'Error at ' || lc_error_loc
                            ,p_error_message_count     => 1
                            ,p_error_message_code      => 'E'
                            ,p_error_message           => SQLERRM
                            ,p_error_message_severity  => 'Major'
                            ,p_notify_flag             => 'N'
                            ,p_object_type             => 'APDM CreditMemo for RTV'
                                              );
            END;

            FND_FILE.PUT_LINE(FND_FILE.LOG,'Starting Checkrun Id for RTV:' ||ln_checkrun_from );
            FND_FILE.PUT_LINE(FND_FILE.LOG,'Ending Checkrun Id for RTV  :' ||ln_checkrun_to );

            ln_conc_request_id := fnd_request.submit_request(
                                                             'xxfin'
                                                            ,'XXAPRTVAPDM'
                                                            ,NULL
                                                            ,NULL
                                                            ,NULL
                                                            ,ln_checkrun_from
                                                            ,ln_checkrun_to);

               FND_FILE.PUT_LINE(FND_FILE.LOG,' Request ID - RTV : ' ||ln_conc_request_id );

         ELSE

            FND_FILE.PUT_LINE(FND_FILE.LOG,'No Data Found For RTV');

         END IF;

      EXCEPTION

         WHEN OTHERS THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG,'In Others of RTV');
            FND_FILE.PUT_LINE(FND_FILE.LOG,SQLERRM ||' - '|| lc_error_loc);

            XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                          p_program_type            => 'CONCURRENT PROGRAM'
                         ,p_program_name            => lc_concurrent_program_name
                         ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                         ,p_module_name             => 'AP'
                         ,p_error_location          => 'Error at ' || lc_error_loc
                         ,p_error_message_count     => 1
                         ,p_error_message_code      => 'E'
                         ,p_error_message           => SQLERRM 
                         ,p_error_message_severity  => 'Major'
                         ,p_notify_flag             => 'N'
                         ,p_object_type             => 'APDM CreditMemo for RTV'
                                           );
      END;

   END APDMREP;

END XX_AP_APDM_CHGRTV_PKG;

/

SHO ERR