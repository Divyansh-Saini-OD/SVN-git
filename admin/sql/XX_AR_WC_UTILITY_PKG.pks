CREATE OR REPLACE PACKAGE XX_AR_WC_UTILITY_PKG
AS
-- +===========================================================================+
-- |                  Office Depot - Project Simplify                          |
-- |                        Office Depot Organization                          |
-- +===========================================================================+
-- | Name         : XX_AR_WC_UTILITY_PKG                                       |
-- |                                                                           |
-- | RICE#        : I2158                                                      |
-- |                                                                           |
-- | Description  : This package contains procedures to execute the            |
-- |                necessary pre-processing and post-processing steps         |
-- |                required for extracting/generating data for WebCollect     |
-- |                                                                           |
-- |                                                                           |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version    Date         Author         Remarks                             |
-- |=========  ===========  =============  ====================================|
-- |  1.0      15-DEC-2011  R.Aldridge     Initial Verion                      |
-- |                                                                           |
-- |  1.1      27-JAN-2012  R.Aldridge     Add ar_pre_conversion procedure     |
-- |                                                                           |
-- |  1.2      04-FEB-2012  R.Aldridge     Defect 16768 - Create new utility   |
-- |                                       to remove special characters        |
-- |                                                                           |
-- |  1.3      07-MAR-2012  R.Aldridge     Defect 17213 - Changes for          | 
-- |                                       customer_id difference              |
-- |                                       (override pmt sched customer id)    |
-- |                                                                           |
-- |  1.4      15-MAR-2012  R.Aldridge     Defect 17213 - Revert to 162388     | 
-- |                                                                           |
-- |  1.5      07-MAR-2012  R.Aldridge     Defect 17213 - Changes for          | 
-- |                                       customer_id difference              |
-- |                                       (override receipt customer id)      |
-- |                                                                           |
-- |  1.6      28-MAR-2012  R.Aldridge     Defect 17805 - Added new procedure  | 
-- |                                       copy_staged_recs to copy staged     |
-- |                                       trans to a temp table               |
-- +===========================================================================+

   -- Record type declaration
   TYPE upd_ps_rec_type IS RECORD (
      payment_schedule_id        ar_payment_schedules_all.PAYMENT_SCHEDULE_ID%TYPE
     ,status                     ar_payment_schedules_all.STATUS%TYPE
     ,class                      ar_payment_schedules_all.CLASS%TYPE
     ,cust_trx_type_id           ra_cust_trx_types_all.CUST_TRX_TYPE_ID%TYPE
     ,customer_id                ar_payment_schedules_all.CUSTOMER_ID%TYPE
     ,customer_site_use_id       ar_payment_schedules_all.CUSTOMER_SITE_USE_ID%TYPE
     ,custmer_trx_id             ar_payment_schedules_all.CUSTOMER_TRX_ID%TYPE
     ,cash_receipt_id            ar_payment_schedules_all.CASH_RECEIPT_ID%TYPE
     ,last_update_date           ar_payment_schedules_all.LAST_UPDATE_DATE%TYPE
     ,amount_due_original        ar_payment_schedules_all.AMOUNT_DUE_ORIGINAL%TYPE
     ,amount_due_remaining       ar_payment_schedules_all.AMOUNT_DUE_REMAINING%TYPE
     ,amount_applied             ar_payment_schedules_all.AMOUNT_APPLIED%TYPE
     ,amount_adjusted            ar_payment_schedules_all.AMOUNT_ADJUSTED%TYPE
     ,amount_in_dispute          ar_payment_schedules_all.AMOUNT_IN_DISPUTE%TYPE
     ,amount_credited            ar_payment_schedules_all.AMOUNT_CREDITED%TYPE
     ,cash_applied_amount_last   ar_payment_schedules_all.CASH_APPLIED_AMOUNT_LAST%TYPE
     ,cash_receipt_amount_last   ar_payment_schedules_all.CASH_RECEIPT_AMOUNT_LAST%TYPE
     ,adjustment_amount_last     ar_payment_schedules_all.ADJUSTMENT_AMOUNT_LAST%TYPE
     ,creation_date              ar_payment_schedules_all.CREATION_DATE%TYPE
     ,created_by                 ar_payment_schedules_all.CREATED_BY%TYPE
     ,pmt_upd_request_id         ar_payment_schedules_all.REQUEST_ID%TYPE
     ,pmt_upd_creation_date      ar_payment_schedules_all.CREATION_DATE%TYPE
     ,ext_type                   xx_ar_wc_upd_ps.ext_type%TYPE
     ,cycle_date                 xx_ar_wc_upd_ps.cycle_date%TYPE
     ,batch_num                  xx_ar_wc_upd_ps.batch_num%TYPE
   );

   -- Table type declaration
   TYPE upd_ps_tbl_type IS TABLE OF upd_ps_rec_type;

   -- +===================================================================+
   -- | FUNCTION   : REMOVE_SPECIAL_CHARACTERS                            |
   -- |                                                                   |
   -- | DESCRIPTION: Removes special characters from text string          |
   -- |                                                                   |
   -- | PARAMETERS : p_text_string     IN                                 |
   -- |                                                                   |
   -- |                                                                   |
   -- | RETURNS    : varchar2                                             |
   -- +===================================================================+
   FUNCTION remove_special_characters (p_text_string     IN   VARCHAR2)
   RETURN VARCHAR2;

   -- +===================================================================+
   -- | PROCEDURE  : VALIDATE_PARAM_TRANS_VALUE                           |
   -- |                                                                   |
   -- | DESCRIPTION: Determines if paramter is not null, if so it is used |
   -- |              else translation value is used                       |
   -- |                                                                   |
   -- | PARAMETERS : p_conc_parameter     IN                              |
   -- |              p_trans_value        IN                              |
   -- |              p_final_setting     OUT                              |
   -- |                                                                   |
   -- | RETURNS    : p_final_setting     OUT                              |
   -- +===================================================================+
   FUNCTION validate_param_trans_value (p_conc_parameter      IN   VARCHAR2
                                       ,p_trans_value         IN   VARCHAR2)
   RETURN VARCHAR2;

   -- +====================================================================+
   -- | Name       : COMPUTE_STATS                                         |
   -- |                                                                    |
   -- | Description: This procedure is used gather statistics              |
   -- |               to log file                                          |
   -- |                                                                    |
   -- | Parameters : p_compute_stats =>                                    |
   -- |              p_schema        =>                                    |
   -- |              p_tablename     =>                                    |
   -- |                                                                    |
   -- | Returns    : none                                                  |
   -- +====================================================================+
   PROCEDURE compute_stat (p_compute_stats   IN  VARCHAR2
                          ,p_ownname         IN  VARCHAR2
                          ,p_tabname         IN  VARCHAR2);

   -- +====================================================================+
   -- | Name       : PRINT_TIME_STAMP_TO_LOGFILE                           |
   -- |                                                                    |
   -- | Description: This private procedure is used to print the time to   |
   -- |              the log                                               |
   -- |                                                                    |
   -- | Parameters : none                                                  |
   -- |                                                                    |
   -- | Returns    : none                                                  |
   -- +====================================================================+
   PROCEDURE print_time_stamp_to_logfile;

   -- +===================================================================+
   -- | PROCEDURE  : LOCATION_AND_LOG                                     |
   -- |                                                                   |
   -- | DESCRIPTION: Performs the following actions based on parameters   |
   -- |              1. Sets gc_error_location                            |
   -- |              2. Writes to log file if debug is on                 |
   -- |                                                                   |
   -- | PARAMETERS : p_debug, p_debug_msg                                 |
   -- |                                                                   |
   -- | RETURNS    : None                                                 |
   -- +===================================================================+
   PROCEDURE location_and_log (p_debug           IN  VARCHAR2
                              ,p_debug_msg       IN  VARCHAR2);

   -- +====================================================================+
   -- | Name       : GET_INTERFACE_SETTINGS                                |
   -- |                                                                    |
   -- | Description:                                                       |
   -- |                                                                    |
   -- | Parameters :                                                       |
   -- |                                                                    |
   -- | Returns    :                                                       |
   -- +====================================================================+
   PROCEDURE get_interface_settings (p_process_type       IN    VARCHAR2
                                    ,p_bulk_limit         OUT   NUMBER
                                    ,p_delimiter          OUT   VARCHAR2
                                    ,p_num_threads_delta  OUT   NUMBER
                                    ,p_file_name          OUT   VARCHAR2
                                    ,p_email              OUT   VARCHAR2
                                    ,p_gather_stats       OUT   VARCHAR2
                                    ,p_line_size          OUT   NUMBER
                                    ,p_file_path          OUT   VARCHAR2
                                    ,p_num_records        OUT   NUMBER
                                    ,p_debug              OUT   VARCHAR2
                                    ,p_ftp_file_path      OUT   VARCHAR2
                                    ,p_arch_file_path     OUT   VARCHAR2
                                    ,p_full_num_days      OUT   NUMBER
                                    ,p_num_threads_full   OUT   NUMBER
                                    ,p_num_threads_file   OUT   NUMBER
                                    ,p_child_conc_delta   OUT   VARCHAR2
                                    ,p_child_conc_full    OUT   VARCHAR2
                                    ,p_child_conc_file    OUT   VARCHAR2
                                    ,p_staging_table      OUT   VARCHAR2
                                    ,p_retrieved          OUT   BOOLEAN
                                    ,p_error_message      OUT   VARCHAR2
                                    ,p_print_to_req_log   IN    VARCHAR2 DEFAULT 'Y');

   -- +====================================================================+
   -- | Name       : GET_CONTROL_INFO                                      |
   -- |                                                                    |
   -- | Description:                                                       |
   -- |                                                                    |
   -- | Parameters :                                                       |
   -- |                                                                    |
   -- | Returns    :                                                       |
   -- +====================================================================+
   PROCEDURE get_control_info (p_cycle_date               IN   DATE
                              ,p_batch_num                IN   NUMBER
                              ,p_process_type             IN   VARCHAR2
                              ,p_action_type              IN   VARCHAR2
                              ,p_delta_from_date          OUT  DATE
                              ,p_full_from_date           OUT  DATE
                              ,p_control_to_date          OUT  DATE
                              ,p_post_process_status      OUT  VARCHAR2
                              ,p_ready_to_execute         OUT  BOOLEAN
                              ,p_reprocessing_required    OUT  BOOLEAN
                              ,p_reprocess_cnt            OUT  NUMBER
                              ,p_retrieved                OUT  BOOLEAN
                              ,p_error_message            OUT  VARCHAR2);

   -- +====================================================================+
   -- | Name       : AR_PRE_PROCESS                                        |
   -- |                                                                    |
   -- | Description:                                                       |
   -- |                                                                    |
   -- | Parameters :                                                       |
   -- |                                                                    |
   -- | Returns    :                                                       |
   -- +====================================================================+
   PROCEDURE ar_pre_process (p_errbuf         OUT  VARCHAR2
                            ,p_retcode        OUT  NUMBER
                            ,p_cycle_date     IN   VARCHAR2
                            ,p_batch_num      IN   NUMBER
                            ,p_compute_stats  IN   VARCHAR2
                            ,p_debug          IN   VARCHAR2
                            ,p_process_type   IN   VARCHAR2);

   -- +====================================================================+
   -- | Name       : AR_UPD_PS                                             |
   -- |                                                                    |
   -- | Description:                                                       |
   -- |                                                                    |
   -- | Parameters :                                                       |
   -- |                                                                    |
   -- | Returns    :                                                       |
   -- +====================================================================+
   PROCEDURE ar_upd_ps (p_errbuf         OUT  VARCHAR2
                       ,p_retcode        OUT  NUMBER
                       ,p_cycle_date     IN   VARCHAR2
                       ,p_batch_num      IN   NUMBER
                       ,p_compute_stats  IN   VARCHAR2
                       ,p_debug          IN   VARCHAR2
                       ,p_process_type   IN   VARCHAR2
                       ,p_action_type    IN   VARCHAR2);

   -- +====================================================================+
   -- | Name       : AR_POST_PROCESS                                       |
   -- |                                                                    |
   -- | Description:                                                       |
   -- |                                                                    |
   -- | Parameters :                                                       |
   -- |                                                                    |
   -- | Returns    :                                                       |
   -- +====================================================================+
   PROCEDURE ar_post_process (p_errbuf         OUT  VARCHAR2
                             ,p_retcode        OUT  NUMBER
                             ,p_cycle_date     IN   VARCHAR2
                             ,p_batch_num      IN   NUMBER
                             ,p_compute_stats  IN   VARCHAR2
                             ,p_debug          IN   VARCHAR2
                             ,p_process_type   IN   VARCHAR2);

   -- +====================================================================+
   -- | Name       : AR_PRE_CONVERSION                                     |
   -- |                                                                    |
   -- | Description:                                                       |
   -- |                                                                    |
   -- | Parameters :                                                       |
   -- |                                                                    |
   -- | Returns    :                                                       |
   -- +====================================================================+
   PROCEDURE ar_pre_conversion (p_errbuf         OUT  VARCHAR2
                               ,p_retcode        OUT  NUMBER
                               ,p_cycle_date     IN   VARCHAR2
                               ,p_batch_num      IN   NUMBER
                               ,p_compute_stats  IN   VARCHAR2
                               ,p_debug          IN   VARCHAR2
                               ,p_process_type   IN   VARCHAR2);

   -- +====================================================================+
   -- | Name       : COPY_STAGED_RECS                                      |
   -- |                                                                    |
   -- | Description: This procedure is used for copying records from       |
   -- |              staging tables to temporary tables                    |
   -- |                                                                    |
   -- | Parameters : p_truncate_flag   IN                                  |
   -- |              p_compute_stats   IN                                  |
   -- |              p_debug           IN                                  |
   -- |                                                                    |
   -- |              p_errbuf          OUT                                 |
   -- |              p_retcode         OUT                                 |
   -- |                                                                    |
   -- | Returns    : none                                                  |
   -- +====================================================================+
   PROCEDURE copy_staged_recs (p_errbuf         OUT  VARCHAR2
                              ,p_retcode        OUT  NUMBER
                              ,p_truncate_flag  IN   VARCHAR2
                              ,p_compute_stats  IN   VARCHAR2
                              ,p_debug          IN   VARCHAR2);

END XX_AR_WC_UTILITY_PKG;
/

show errors
