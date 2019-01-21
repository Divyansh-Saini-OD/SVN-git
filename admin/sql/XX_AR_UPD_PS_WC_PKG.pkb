CREATE OR REPLACE PACKAGE BODY XX_AR_UPD_PS_WC_PKG
AS
   /*=========================================================================================+
   |  NAME:       XX_AR_UPD_PS_WC_PKG .                                                       |
   |  PURPOSE:    This package contains procedures for the AR Payment                         |
   |              schedules update records for newly eligible customers.                      |
   |  REVISIONS:                                                                              |
   |  Ver        Date        Author           Description                                     |
   |  ----------------------------------------------------                                    |
   |  1.0        03/11/2011  Maheswararao N   Created this package.                           |
   +==========================================================================================+*/
   lc_msg   VARCHAR2 (1000);
   gd_creation_date   DATE                                 := SYSDATE;
   gn_created_by      NUMBER     := NVL (fnd_profile.VALUE ('USER_ID'),-1);

   PROCEDURE write_log (
      p_debug_flag   IN   VARCHAR2
     ,p_msg          IN   VARCHAR2
   )
   /*+=====================================================================================+
   |Name        :write_log                                                                 |
   |Description :This procedure is used to log any messages to log file based on           |
   |             debug flag parameter value                                                |
   |                                                                                       |
   |                                                                                       |
   |Parameters : p_debug_flag,p_msg                                                        |
   |                                                                                       |
   |                                                                                       |
   |Returns    : NA                                                                        |
   |                                                                                       |
   |                                                                                       |
   +=======================================================================================+*/
   IS
   BEGIN
      IF p_debug_flag = 'Y'
      THEN
         fnd_file.put_line (fnd_file.LOG, p_msg || TO_CHAR (SYSDATE, 'DD/MON/YYYY HH24:MI:SS'));
      END IF;
   END write_log;

   PROCEDURE compute_stats (
      p_compute_stats   IN   VARCHAR2
     ,p_schema          IN   VARCHAR2
     ,p_tablename       IN   VARCHAR2
   )
   IS
   /*+=============================================================================+
   | Name       : compute_stats                                                    |
   |                                                                               |
   | Description: This procedure is used to to gather table statistics             |
   |                     based on the parameter values                             |
   |                                                                               |
   | Parameters : p_compute_stats                                                  |
   |              p_schema                                                         |
   |              p_tablename                                                      |
   | Returns    : none                                                             |
   +===============================================================================+*/
   BEGIN
      IF p_compute_stats = 'Y'
      THEN
         fnd_stats.gather_table_stats (ownname      => p_schema
                                        , tabname => p_tablename);
      END IF;
   END compute_stats;

   PROCEDURE upd_ps_stg (
      p_debug           IN       VARCHAR2
     ,p_batch_limit     IN       NUMBER
     ,p_compute_stats   IN       VARCHAR2
     ,p_err_code        OUT      NUMBER
     ,p_num_days        IN       NUMBER
   )
   IS
      /*+=======================================================================+
      |                  Office Depot - Project FIT                             |
      |                       Cap Gemini                                        |
      +=========================================================================+
      | Name : upd_ps_stg                                                       |
      | Description : Procedure to insert the values in stage table             |
      |                                                                  .      |
      |                                                                         |
      | Parameters :    p_batch                                                 |
      |===============                                                          |
      |Version   Date          Author              Remarks                      |
      |=======   ==========   =============   ==================================|
      |  1.0     03-NOV-11   Maheswararao N   Initial version                   |
      +=========================================================================+*/

      --Variable declaration of Table type
      lt_upd_ps       upd_ps_tbl_type;
      ln_count        NUMBER;

      --cursor declaration: This is used to fetch the total payment schedules update records
      CURSOR lcu_upd_ps (
         p_num_days   IN   NUMBER
      )
      IS
         SELECT payment_schedule_id
               ,status
               ,class
               ,cust_trx_type_id
               ,customer_id
               ,customer_site_use_id
               ,customer_trx_id
               ,cash_receipt_id
               ,APS.last_update_date
               ,amount_due_original
               ,amount_due_remaining
               ,amount_applied
               ,amount_adjusted
               ,amount_in_dispute
               ,amount_credited
               ,cash_applied_amount_last
               ,cash_receipt_amount_last
               ,adjustment_amount_last
               ,gd_creation_date
               ,gn_created_by
           FROM apps.ar_payment_schedules_all APS
               ,xxcrm.xx_crm_wcelg_cust XCWC
          WHERE APS.customer_id = XCWC.cust_account_id AND XCWC.ps_ext = 'N' AND aps.last_update_date BETWEEN (SYSDATE - (p_num_days)) AND SYSDATE;

      ln_batchlimit   NUMBER;
   BEGIN
      EXECUTE IMMEDIATE 'TRUNCATE TABLE  XXFIN.XX_AR_WC_UPD_PS';

      lc_msg := 'Truncate Ends for XX_AR_WC_UPD_PS table at ';
      write_log (p_debug, lc_msg);
      --lcu_upd_ps cursor Loop started here
      ln_batchlimit := p_batch_limit;

      OPEN lcu_upd_ps (p_num_days);

      lc_msg := 'cursor lcu_upd_ps started at ';
      write_log (p_debug, lc_msg);

      LOOP
         FETCH lcu_upd_ps
         BULK COLLECT INTO lt_upd_ps LIMIT ln_batchlimit;

         FORALL i IN 1 .. lt_upd_ps.COUNT
            INSERT INTO XX_AR_WC_UPD_PS
                 VALUES lt_upd_ps (i);
         COMMIT;
         EXIT WHEN lcu_upd_ps%NOTFOUND;
      END LOOP;

      CLOSE lcu_upd_ps;

      lc_msg := 'cursor lcu_upd_ps ended at ';
      write_log (p_debug, lc_msg);
      --lcu_upd_ps curosr Loop ended here
      COMMIT;

      SELECT COUNT (1)
        INTO ln_count
        FROM XX_AR_WC_UPD_PS;

      fnd_file.put_line (fnd_file.LOG, 'Total records inserted into XX_AR_WC_UPD_PS table is: ' || ln_count);
      lc_msg := 'compute statistics for table XX_AR_WC_UPD_PS at ';
      write_log (p_debug, lc_msg);
      compute_stats (p_compute_stats
                    ,'XXFIN'
                    ,'XX_AR_WC_UPD_PS'
                    );
   EXCEPTION
      WHEN OTHERS
      THEN
         fnd_file.put_line (fnd_file.LOG, 'Insertion failed in XX_AR_WC_UPD_PS');
         fnd_file.put_line (fnd_file.LOG, '');
   END upd_ps_stg;

   --Start of main procedure
   PROCEDURE ar_upd_ps_main (
      p_errbuf          OUT      VARCHAR2
     ,p_retcode         OUT      NUMBER
     ,p_debug           IN       VARCHAR2
     ,p_compute_stats   IN       VARCHAR2
   )
   /*+=========================================================================================+
   |Name        : ar_upd_ps_main                                                               |
   |Description : This procedure is used to call the above three                               |
   |              procedures. while registering concurrent                                     |
   |              program this procedure will be used                                          |
   |                                                                                           |
   |Parameters : p_debug ,                                                                     |                                                                                      |
   |Returns    : NA                                                                            |
   |                                                                                           |
   |                                                                                           |
   +===========================================================================================+*/
   IS
      -- Variable Declaration
      ln_batch_limit   NUMBER;
      lc_debug_flag    VARCHAR2 (1);
      lc_debug         VARCHAR2 (1);
      lc_comp_stats    VARCHAR2 (1);
      lc_comp          VARCHAR2 (1);
      ln_err_code      NUMBER;
      ln_num_of_days   NUMBER;

   BEGIN
      lc_debug_flag := p_debug;

      BEGIN
         lc_msg := 'Retrieving Translation definition Values for AR Recon extraction program at ';
         write_log (p_debug, lc_msg);

         SELECT xftv.target_value1
               ,xftv.target_value6
               ,xftv.target_value10
               ,xftv.target_value13
           INTO ln_batch_limit
               ,lc_comp_stats
               ,lc_debug_flag
               ,ln_num_of_days
           FROM xx_fin_translatevalues xftv
               ,xx_fin_translatedefinition xftd
          WHERE xftv.translate_id = xftd.translate_id
            AND xftd.translation_name = 'XXOD_WEBCOLLECT_INTERFACE'
            AND xftv.source_value1 = 'AR_UPD_PS'
            AND SYSDATE BETWEEN xftv.start_date_active AND NVL (xftv.end_date_active, SYSDATE + 1)
            AND SYSDATE BETWEEN xftd.start_date_active AND NVL (xftd.end_date_active, SYSDATE + 1)
            AND xftv.enabled_flag = 'Y'
            AND xftd.enabled_flag = 'Y';
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            fnd_file.put_line (fnd_file.LOG, 'NO data found while getting translation defination values' || SQLERRM);
      END;

      IF p_debug IS NULL
      THEN
         lc_debug := lc_debug_flag;
      ELSE
         lc_debug := p_debug;
      END IF;

      IF p_compute_stats IS NULL
      THEN
         lc_comp := lc_comp_stats;
      ELSE
         lc_comp := p_compute_stats;
      END IF;

      fnd_file.put_line (fnd_file.LOG, '--------- OD : AR Payment Schedules - Last Update Program -----------------');
      fnd_file.put_line (fnd_file.LOG, 'Parameters Entered');
      fnd_file.put_line (fnd_file.LOG, 'bulk collect batch limit :' || ln_batch_limit);
      fnd_file.put_line (fnd_file.LOG, 'Compute Stats Flag :' || lc_comp_stats);
      fnd_file.put_line (fnd_file.LOG, 'Debug Flag:' || lc_debug_flag);
      fnd_file.put_line (fnd_file.LOG, 'Start of upd_ps_stg program execution at ' || TO_CHAR (SYSDATE, 'DD/MON/YYYY HH24:MI:SS'));
      upd_ps_stg (lc_debug
                 ,ln_batch_limit
                 ,lc_comp
                 ,ln_err_code
                 ,ln_num_of_days
                 );
      fnd_file.put_line (fnd_file.LOG, 'End of upd_ps_stg program at ' || TO_CHAR (SYSDATE, 'DD/MON/YYYY HH24:MI:SS'));

      IF ln_err_code <> 0
      THEN
         p_retcode := ln_err_code;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         fnd_file.put_line (fnd_file.LOG, 'Exception is raised in main procedure');
         p_retcode := 2;
         lc_msg := 'AR Payment Schedules - Last Update Program successfully completed at ';
         write_log (p_debug, lc_msg);
   END ar_upd_ps_main;
--end of XX_AR_UPD_PS_WC_PKG Package Body
END XX_AR_UPD_PS_WC_PKG;
/

SHOW ERRORS;