CREATE OR REPLACE PACKAGE BODY XX_AR_RECON_REPORT_PKG
AS
-- ====================================================================================
--   NAME:       XX_AR_RECON_REPORT_PKG .
--   PURPOSE:    This package contains procedures for the AR Recon Report process.
--   REVISIONS:
--   Ver        Date        Author           Description
--   ---------  ----------  ---------------  -----------------------------------------
--   1.0        03/10/2011  Maheswararao N    Created this package.
--   1.1        21/10/2011  Maheswararao N    Modified based on MD70 changes
--   1.2        19/12/2011  Maheswararao N    Modified based on MD70 changes
--   1.3        11/02/2016  Vasu Raparla      Removed Schema References for R.12.2
-- ====================================================================================
-- Global Variable Declarations here
   gn_limit                   xx_fin_translatevalues.target_value1%TYPE;
   gc_delimiter               xx_fin_translatevalues.target_value2%TYPE;
   gc_file_name               xx_fin_translatevalues.target_value4%TYPE;
   gc_email                   xx_fin_translatevalues.target_value5%TYPE;
   gc_compute_stats           xx_fin_translatevalues.target_value6%TYPE;
   gn_line_size               xx_fin_translatevalues.target_value7%TYPE;
   gc_file_path               xx_fin_translatevalues.target_value8%TYPE;
   gn_num_records             xx_fin_translatevalues.target_value9%TYPE;
   gc_debug                   xx_fin_translatevalues.target_value10%TYPE;
   gc_ftp_file_path           xx_fin_translatevalues.target_value11%TYPE;
   gc_arch_file_path          xx_fin_translatevalues.target_value12%TYPE;
   gc_staging_table           xx_fin_translatevalues.target_value19%TYPE;
   gc_process_type            xx_ar_mt_wc_details.process_type%TYPE   := 'AR_RECON';
   gn_threads_delta           NUMBER;
   gn_threads_full            NUMBER;
   gn_threads_file            NUMBER;
   gc_conc_short_delta        xx_fin_translatevalues.target_value16%TYPE;
   gc_conc_short_full         xx_fin_translatevalues.target_value17%TYPE;
   gc_conc_short_file         xx_fin_translatevalues.target_value18%TYPE;
   gn_full_num_days           NUMBER;
   gb_retrieved_trans         BOOLEAN                                       := FALSE;
   gc_err_msg_trans           VARCHAR2 (100)                                := NULL;
   gd_cycle_date              DATE;
   GC_YES                     VARCHAR2 (1)                                  := 'Y';
   gc_error_loc               VARCHAR2 (2000)                               := NULL;
   -- Variables for Cycle Date and Batch Cycle Settings
   gc_action_type             xx_ar_mt_wc_details.action_type%TYPE;
   --  gd_cycle_date                 xx_ar_wc_ext_control.cycle_date%TYPE;
   gn_batch_num               xx_ar_wc_ext_control.batch_num%TYPE;
   gb_ready_to_execute        BOOLEAN                                       := FALSE;
   gb_reprocessing_required   BOOLEAN                                       := FALSE;
   gb_retrieved_cntl          BOOLEAN                                       := FALSE;
   gc_err_msg_cntl            VARCHAR2 (100)                                := NULL;
   gc_post_process_status     VARCHAR (1)                                   := 'Y';
   gd_delta_from_date         DATE;
   gd_full_from_date          DATE;
   gd_control_to_date         DATE;
   gc_reprocess_cnt           NUMBER;
   -- Custom Exceptions
   EX_NO_CONTROL_RECORD       EXCEPTION;
   EX_CYCLE_COMPLETED         EXCEPTION;
   EX_STAGING_COMPLETED       EXCEPTION;

/*=====================================================================================+
| Name       : GET_TRANS_SETTINGS                                                     |
| Description: This procedure is used to fetch the transalation definition details    |
|                                                                                     |
| Parameters : none                                                                   |
|                                                                                     |
| Returns    : none                                                                   |
+=====================================================================================*/
   PROCEDURE get_trans_settings
   IS
   BEGIN
--========================================================================
-- Retrieve Interface Settings from Translation Definition
--========================================================================
      xx_ar_wc_utility_pkg.get_interface_settings (p_process_type           => gc_process_type
                                                  ,p_bulk_limit             => gn_limit
                                                  ,p_delimiter              => gc_delimiter
                                                  ,p_num_threads_delta      => gn_threads_delta
                                                  ,p_file_name              => gc_file_name
                                                  ,p_email                  => gc_email
                                                  ,p_gather_stats           => gc_compute_stats
                                                  ,p_line_size              => gn_line_size
                                                  ,p_file_path              => gc_file_path
                                                  ,p_num_records            => gn_num_records
                                                  ,p_debug                  => gc_debug
                                                  ,p_ftp_file_path          => gc_ftp_file_path
                                                  ,p_arch_file_path         => gc_arch_file_path
                                                  ,p_full_num_days          => gn_full_num_days
                                                  ,p_num_threads_full       => gn_threads_full
                                                  ,p_num_threads_file       => gn_threads_file
                                                  ,p_child_conc_delta       => gc_conc_short_delta
                                                  ,p_child_conc_full        => gc_conc_short_full
                                                  ,p_child_conc_file        => gc_conc_short_file
                                                  ,p_staging_table          => gc_staging_table
                                                  ,p_retrieved              => gb_retrieved_trans
                                                  ,p_error_message          => gc_err_msg_trans
                                                  );
      xx_ar_wc_utility_pkg.print_time_stamp_to_logfile;
   END get_trans_settings;

   PROCEDURE ar_recon_report (
      p_errbuf         OUT      VARCHAR2
     ,p_retcode        OUT      NUMBER    
     ,p_debug          IN       VARCHAR2
     ,p_process_type   IN       VARCHAR2
   )
   IS
   -- +=========================================================================+
   -- |                  Office Depot - Project FIT                             |
   -- |                       Cap Gemini                                        |
   -- +=========================================================================+
   -- | Name : ar_recon_report                                                  |
   -- | Description : Procedure to generate a summary report from WC to Non WC  |
   -- |                                                                  .      |
   -- |                                                                         |
   -- | Parameters :    Errbuf and retcode                                      |
   -- |===============                                                          |
   -- |Version   Date          Author              Remarks                      |
   -- |=======   ==========   =============   ==================================|
   -- |  1.0     04-OCT-11   Maheswararao N   Initial version                   |
-- +============================================================================+
      ln_wc_usd      NUMBER         := 0;
      ln_wc_cad      NUMBER         := 0;
      ln_nonwc_usd   NUMBER         := 0;
      ln_nonwc_cad   NUMBER         := 0;
      ln_tot_usd     NUMBER         := 0;
      ln_tot_cad     NUMBER         := 0;
      lc_msg         VARCHAR2 (360);
   BEGIN
      FND_FILE.PUT_LINE (fnd_file.LOG, 'Start  ar_recon_report program at' || TO_CHAR (SYSDATE, 'DD/MON/YYYY HH24:MI:SS'));
      FND_FILE.PUT_LINE (FND_FILE.LOG, '********Entered Parameters For AR - WC Open Balance Summary Report *******************');     
      FND_FILE.PUT_LINE (FND_FILE.LOG, '            Process Type             :' || p_process_type);
      FND_FILE.PUT_LINE (FND_FILE.LOG, '            Debug Flag               :' || p_debug);
      FND_FILE.PUT_LINE (FND_FILE.LOG, '****************************************************************************************');
      xx_ar_wc_utility_pkg.print_time_stamp_to_logfile;
      xx_ar_wc_utility_pkg.location_and_log (GC_YES, 'Retrieving Interface Settings From Translation Definition' || CHR (10));
      get_trans_settings;
      xx_ar_wc_utility_pkg.location_and_log (gc_debug, 'Determine if parameter value for debug/stats is used' || CHR (10));
      gc_debug := xx_ar_wc_utility_pkg.validate_param_trans_value (p_debug, gc_debug);

      FND_FILE.PUT_LINE (FND_FILE.LOG, '*******************Derived Parameters For AR - WC Open Balance Summary Report*************');
      FND_FILE.PUT_LINE (FND_FILE.LOG, '                Debug Flag        :' || gc_debug);
      FND_FILE.PUT_LINE (FND_FILE.LOG, '******************************************************************************************');
      xx_ar_wc_utility_pkg.location_and_log (gc_debug, 'Begin OD: AR - WC Open Balance Summary Report execution' || CHR (10));

      BEGIN
         xx_ar_wc_utility_pkg.location_and_log (gc_debug, 'Getting Summary for Webcollect and Non Webcollect by Currency code' || CHR (10));

         SELECT SUM (a) "WC_USD"
               ,SUM (b) "NONWC_USD"
               ,SUM (c) "WC_CAD"
               ,SUM (d) "NONWC_CAD"
           INTO ln_wc_usd
               ,ln_nonwc_usd
               ,ln_wc_cad
               ,ln_nonwc_cad
           FROM (SELECT DECODE (recon_to_wc
                               ,'Y', DECODE (invoice_currency_code
                                            ,'USD', amount_due_remaining
                                            ,0
                                            )
                               ) a
                       ,DECODE (recon_to_wc
                               ,'N', DECODE (invoice_currency_code
                                            ,'USD', amount_due_remaining
                                            ,0
                                            )
                               ) b
                       ,DECODE (recon_to_wc
                               ,'Y', DECODE (invoice_currency_code
                                            ,'CAD', amount_due_remaining
                                            ,0
                                            )
                               ) c
                       ,DECODE (recon_to_wc
                               ,'N', DECODE (invoice_currency_code
                                            ,'CAD', amount_due_remaining
                                            ,0
                                            )
                               ) d
                   FROM xx_ar_recon_open_itm);
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            fnd_file.put_line (fnd_file.LOG, 'No data found for AR Recon Report');
            fnd_file.put_line (fnd_file.LOG, '');
         WHEN OTHERS
         THEN
            FND_FILE.PUT_LINE (FND_FILE.LOG, 'Others exception in AR Open Item Dump Program :' || SQLERRM);
            xx_ar_wc_utility_pkg.print_time_stamp_to_logfile;
            p_retcode := 2;
      END;

      ln_tot_usd := ln_wc_usd + ln_nonwc_usd;
      ln_tot_cad := ln_wc_cad + ln_nonwc_cad;
      FND_FILE.PUT_LINE (FND_FILE.OUTPUT, '*******************OD: AR - WC Open Balance Summary Report *************');
      FND_FILE.PUT_LINE (FND_FILE.OUTPUT, '                  ------------------------------------------  ');
      FND_FILE.PUT_LINE (FND_FILE.OUTPUT, 'Webcollect AR Total  USD   : ' || ln_wc_usd);
      FND_FILE.PUT_LINE (FND_FILE.OUTPUT, 'Webcollect AR Total  CAD   : ' || ln_wc_cad);
      FND_FILE.PUT_LINE (FND_FILE.OUTPUT, 'Non Webcollect AR Total USD: ' || ln_nonwc_usd);
      FND_FILE.PUT_LINE (FND_FILE.OUTPUT, 'Non Webcollect AR Total CAD: ' || ln_nonwc_cad);
      FND_FILE.PUT_LINE (FND_FILE.OUTPUT, 'Total AR USD              : ' || ln_tot_usd);
      FND_FILE.PUT_LINE (FND_FILE.OUTPUT, 'Total AR CAD              : ' || ln_tot_cad);
      FND_FILE.PUT_LINE (FND_FILE.OUTPUT, '************************************************************************');
      xx_ar_wc_utility_pkg.location_and_log (gc_debug, 'End OD: AR - WC Open Balance Summary Report execution' || CHR (10));
   END ar_recon_report;
---------------------------------------------------------------------------------------------------------------------------
--end of XX_AR_RECON_REPORT_PKG Package Body
---------------------------------------------------------------------------------------------------------------------------
END XX_AR_RECON_REPORT_PKG;
/

SHOW ERRORS;