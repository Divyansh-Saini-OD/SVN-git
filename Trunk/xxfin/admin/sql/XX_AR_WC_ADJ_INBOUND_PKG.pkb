CREATE OR REPLACE PACKAGE BODY XX_AR_WC_ADJ_INBOUND_PKG
AS
-- ====================================================================================
--   NAME:       XX_AR_WC_ADJ_INBOUND_PKG .
--   PURPOSE:    This package contains procedures for the Adjustment creation in Oracle AR.
--   REVISIONS:
--   Ver        Date        Author           Description
--   ---------  ----------  ---------------  -----------------------------------------
--   1.0        22/Nov/2011  Maheswararao N    Created this package.
-- ====================================================================================

   -- This procedure is used to log required information to conc program log file
   PROCEDURE write_log (
      p_debug_flag   IN   VARCHAR2
     ,p_msg          IN   VARCHAR2
   )
   IS
   BEGIN
      IF p_debug_flag = 'Y'
      THEN
         fnd_file.put_line (fnd_file.LOG, p_msg);
      END IF;
   END write_log;

-- This procedure is used to create Adjustment in oracle for the approved dispute customer transactions from WC system
  -- +=========================================================================+
     -- |                  Office Depot - Project FIT                             |
     -- |                       Cap Gemini                                        |
     -- +=========================================================================+
     -- | Name : CREATE_ADJ                                                       |
     -- | Description : Procedure to crete Adjustment in oracle                   |
     -- |                                                                  .      |
     -- |                                                                         |
     -- | Parameters :    Errbuf and retcode                                      |
     -- |===============                                                          |
     -- |Version   Date          Author              Remarks                      |
     -- |=======   ==========   =============   ==================================|
     -- |  1.0     22-Nov-11   Maheswararao N   Initial version                   |
-- +============================================================================+
   PROCEDURE CREATE_ADJ (
      p_errbuf    OUT      VARCHAR2
     ,p_retcode   OUT      NUMBER
     ,p_debug     IN       VARCHAR2
   )
   IS
      --  Cursor declaration
      CURSOR lcu_main
      IS
         SELECT CUSTOMER_TRX_ID
               ,AMOUNT
           FROM XX_AR_WC_INBOUND_STG
          WHERE TRX_CATEGORY = 'ADJUSTMENTS';

      -- Local variable declaration
      lr_adj_rec             ar_adjustments%ROWTYPE;
      lc_api_name            VARCHAR2 (20)                                        := 'AR_ADJUST_PUB';
      ln_api_version         NUMBER                                               := 1.0;
      ln_msg_count           NUMBER                                               := 0;
      lc_msg_data            VARCHAR2 (2000);
      ln_new_adjust_id       ar_adjustments.adjustment_id%TYPE;
      ln_new_adjust_number   ar_adjustments.adjustment_number%TYPE;
      lc_return_status       VARCHAR2 (5);
      ln_ps_id               ar_payment_schedules_all.payment_schedule_id%TYPE;
      ln_ps_amt              ar_payment_schedules_all.amount_due_remaining%TYPE;
      ln_upd_count           NUMBER                                               := 0;
      lc_msg                 VARCHAR2 (360);
   BEGIN
      lc_msg := ' Begin AR Adjustment Inbound from Webcollect';
      write_log (p_debug, lc_msg);
      -- fnd_global.apps_initialize(1238119,50890,222);

      /* api- data adjustments mapping record - start */
      lc_msg := ' api- data adjustments mapping record - start';
      write_log (p_debug, lc_msg);
      lr_adj_rec.CREATED_FROM := 'ADJ-API';
      lr_adj_rec.CREATION_DATE := SYSDATE;
      lr_adj_rec.GL_DATE := SYSDATE;
      lr_adj_rec.STATUS := 'W';
      --lr_adj_rec.TYPE                 := 'INVOICE';  --The type of Adjustment like INVOICE,LINE,TAX, FREIGHT,CHARGES
      --lr_adj_rec.PAYMENT_SCHEDULE_ID  := 7752;
      lr_adj_rec.APPLY_DATE := SYSDATE;
      lr_adj_rec.RECEIVABLES_TRX_ID := 676603;                                                                                                                                  -- This is rec activity
      --up_adj_rec.CUSTOMER_TRX_ID      := 135512;       --- Transaction for which adjustment is made
      --lr_adj_rec.AMOUNT               := -100;

      /*  api- data adjustments mapping record - End */
      lc_msg := ' api- data adjustments mapping record - End';
      write_log (p_debug, lc_msg);

      -- Calling Adjustment Creation API
      FOR adj_rec IN lcu_main
      LOOP
         BEGIN
            lc_msg := ' Retrieving Payment schedule ID and amount due remaining for the transaction id';
            write_log (p_debug, lc_msg);

            SELECT payment_schedule_id
                  ,amount_due_remaining
              INTO ln_ps_id
                  ,ln_ps_amt
              FROM ar_payment_schedules_all
             WHERE CUSTOMER_TRX_ID = adj_rec.CUSTOMER_TRX_ID;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               fnd_file.put_line (fnd_file.LOG, 'No Data found for customet trx ID :' || ln_ps_id || ' ' || ln_ps_amt);
            WHEN OTHERS
            THEN
               fnd_file.put_line (fnd_file.LOG, 'Other Exception Raised in getting Payment schedule data :' || SQLERRM);
               p_retcode := 2;
         END;

         IF ln_ps_amt = adj_rec.amount
         THEN
            lr_adj_rec.TYPE := 'INVOICE';
            lr_adj_rec.PAYMENT_SCHEDULE_ID := ln_ps_id;
            lr_adj_rec.AMOUNT := ln_ps_amt;
            lc_msg := ' Calling Create_Adjustment for INVOICE Type ';
            write_log (p_debug, lc_msg);
            AR_ADJUST_PUB.Create_Adjustment (p_api_name               => lc_api_name
                                            ,p_api_version            => ln_api_version
                                            ,p_msg_count              => ln_msg_count
                                            ,p_msg_data               => lc_msg_data
                                            ,p_return_status          => lc_return_status
                                            ,p_adj_rec                => lr_adj_rec
                                            ,p_new_adjust_number      => ln_new_adjust_number
                                            ,p_new_adjust_id          => ln_new_adjust_id
                                            );
            fnd_file.put_line (fnd_file.LOG, 'New Adjustment Number: ' || ln_new_adjust_number);
            fnd_file.put_line (fnd_file.LOG, 'New Adjustment ID: ' || ln_new_adjust_id);

            --IF ln_msg_count >=1 THEN
            IF lc_return_status <> 'S'
            THEN
               FND_FILE.PUT_LINE (FND_FILE.LOG, 'Error Encountered ' || 'Message count is ' || ln_msg_count);

               FOR I IN 1 .. ln_msg_count
               LOOP
                  fnd_file.put_line (fnd_file.LOG, I || '. ' || SUBSTR (FND_MSG_PUB.Get (p_encoded      => FND_API.G_FALSE)
                                                                       ,1
                                                                       ,255
                                                                       ));
               END LOOP;

               RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
            ELSE
               lc_msg := ' Update staging table XX_AR_WC_INBOUND_STG for INVOICE Type ';
               write_log (p_debug, lc_msg);

               UPDATE XX_AR_WC_INBOUND_STG
                  SET TRX_STATUS = 'SUCCESS'
                     ,TRX_MESSAGE = 'New Adjustment Number' || ln_new_adjust_number || 'for CUSTOMER_TRX_ID' || adj_rec.CUSTOMER_TRX_ID
                     ,LAST_UPDATE_DATE = SYSDATE
                WHERE CUSTOMER_TRX_ID = adj_rec.CUSTOMER_TRX_ID AND TRX_CATEGORY = 'ADJUSTMENTS';

               ln_upd_count := ln_upd_count + SQL%ROWCOUNT;
            END IF;
         ELSIF ln_ps_amt > adj_rec.amount
         THEN
            lr_adj_rec.TYPE := 'LINE';
            lr_adj_rec.PAYMENT_SCHEDULE_ID := ln_ps_id;
            lr_adj_rec.AMOUNT := ln_ps_amt;
            lc_msg := ' Calling Create_Adjustment for LINE Type ';
            write_log (p_debug, lc_msg);
            AR_ADJUST_PUB.Create_Adjustment (p_api_name               => lc_api_name
                                            ,p_api_version            => ln_api_version
                                            ,p_msg_count              => ln_msg_count
                                            ,p_msg_data               => lc_msg_data
                                            ,p_return_status          => lc_return_status
                                            ,p_adj_rec                => lr_adj_rec
                                            ,p_new_adjust_number      => ln_new_adjust_number
                                            ,p_new_adjust_id          => ln_new_adjust_id
                                            );
            fnd_file.put_line (fnd_file.LOG, 'New Adjustment Number: ' || ln_new_adjust_number);
            fnd_file.put_line (fnd_file.LOG, 'New Adjustment ID: ' || ln_new_adjust_id);

            IF lc_return_status <> 'S'
            THEN
               FND_FILE.PUT_LINE (FND_FILE.LOG, 'Error Encountered ' || 'Message count is ' || ln_msg_count);

               FOR I IN 1 .. ln_msg_count
               LOOP
                  fnd_file.put_line (fnd_file.LOG, I || '. ' || SUBSTR (FND_MSG_PUB.Get (p_encoded      => FND_API.G_FALSE)
                                                                       ,1
                                                                       ,255
                                                                       ));
               END LOOP;

               RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
            ELSE
               lc_msg := ' Update staging table XX_AR_WC_INBOUND_STG for LINE Type ';
               write_log (p_debug, lc_msg);

               UPDATE XX_AR_WC_INBOUND_STG
                  SET TRX_STATUS = 'SUCCESS'
                     ,TRX_MESSAGE = 'New Adjustment Number' || ln_new_adjust_number || 'for CUSTOMER_TRX_ID' || adj_rec.CUSTOMER_TRX_ID
                     ,LAST_UPDATE_DATE = SYSDATE
                WHERE CUSTOMER_TRX_ID = adj_rec.CUSTOMER_TRX_ID AND TRX_CATEGORY = 'ADJUSTMENTS';

               ln_upd_count := ln_upd_count + SQL%ROWCOUNT;
               COMMIT;
            END IF;
         ELSE
            fnd_file.put_line (fnd_file.LOG
                              , 'Total adjustment amount:' || adj_rec.amount || 'is greater than total amount due remaining ' || ln_ps_amt || 'for cust_trx_id :' || adj_rec.CUSTOMER_TRX_ID);
            p_retcode := 1;
         END IF;
      END LOOP;

      fnd_file.put_line (fnd_file.LOG, 'Total Updated Records in Staging table: ' || ln_upd_count);
      lc_msg := ' End of AR Adjustment Inbound from Webcollect';
      write_log (p_debug, lc_msg);
   EXCEPTION
      WHEN OTHERS
      THEN
         fnd_file.put_line (fnd_file.LOG, 'Other Exception Raised in Adjustment creation inbound program :' || SQLERRM);
         p_retcode := 2;
   END CREATE_ADJ;
---------------------------------------------------------------------------------------------------------------------------
--end of XX_AR_WC_ADJ_INBOUND_PKG Package Body
---------------------------------------------------------------------------------------------------------------------------
END XX_AR_WC_ADJ_INBOUND_PKG;
/

SHOW ERRORS;