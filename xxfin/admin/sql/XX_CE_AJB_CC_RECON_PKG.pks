/* Formatted on 2008/07/24 11:32 (Formatter Plus v4.8.8) */
CREATE OR REPLACE PACKAGE xx_ce_ajb_cc_recon_pkg
AS
-- +=================================================================================+
-- |                       Office Depot - Project Simplify                           |
-- |                            Providge Consulting                                  |
-- +=================================================================================+
-- | Name       : XXCEAJBCCRECON.pks                                                 |
-- | Description: Cash Management AJB Creditcard Reconciliation E1310-Extension      |
-- |                                                                                 |
-- |                                                                                 |
-- |Change Record                                                                    |
-- |==============                                                                   |
-- |Version   Date         Authors            Remarks                                |
-- |========  ===========  ===============    ============================           |
-- |DRAFT 1A  14-AUG-2007  Sunayan Mohanty    Initial draft version                  |
-- |          27-NOV-2007  Deepak Gowda       Initial Version                        |
-- |          15-MAY-2008  Deepak Gowda       Defect 6395 added bpel_delete_recs     |
-- |          21-MAY-2008  Deepak Gowda       Defect 6395 added bpel_check_dup_file  |
-- |          02-Jul-2008  Deepak Gowda       Defects 8710 and 8765-Add parameters   |
-- |                                           provider_code and date range to match |
-- |                                           and recon processes                   |
-- |                                                                                 |
-- +=================================================================================+
-- | Name        : RECON_PROCESS                                                     |
-- | Description : This procedure will be used to process the                        |
-- |               Cash Management AJB Creditcard Reconciliation                     |
-- |                                                                                 |
-- | Parameters  : p_run_from_date   IN DATE                                         |
-- |               p_run_to_date     IN DATE                                         |
-- |                                                                                 |
-- | Returns     : x_errbuf                                                          |
-- |               x_retcode                                                         |
-- +=================================================================================+
   PROCEDURE accrual_process (
      x_errmsg          OUT NOCOPY      VARCHAR2
    , x_retstatus       OUT NOCOPY      NUMBER
    , p_process_date    IN              VARCHAR2
    , p_provider_code   IN              VARCHAR2
    , p_ajb_card_type   IN              VARCHAR2
   );

   PROCEDURE recon_process (
      x_errbuf          OUT NOCOPY      VARCHAR2
    , x_retcode         OUT NOCOPY      NUMBER
    , p_provider_code   IN              VARCHAR2
    , p_from_date       IN              VARCHAR2
    , p_to_date         IN              VARCHAR2
    , p_email_id        IN              VARCHAR2 DEFAULT NULL
   );

   PROCEDURE match_stmt_to_ajb_batches (
      x_errbuf          OUT NOCOPY      VARCHAR2
    , x_retcode         OUT NOCOPY      NUMBER
    , p_provider_code   IN              VARCHAR2
    , p_from_date       IN              VARCHAR2
    , p_to_date         IN              VARCHAR2
   );

   FUNCTION get_recon_date (p_bank_rec_id IN xx_ce_ajb999.bank_rec_id%TYPE)
      RETURN DATE;

   PROCEDURE bpel_delete_recs (
      p_table_name   IN       VARCHAR2
    , p_file_name    IN       VARCHAR2
    , p_error_flag   OUT      VARCHAR2
    , p_message      OUT      VARCHAR2
   );

   -- Function BPEL_CHECK_DUP_FILE
   --    Returns 'T' if file has been loaded
   --    Returns 'F' if file has not been loaded
   --    Returns 'E' if error
   FUNCTION bpel_check_dup_file (
      p_table_name   IN   VARCHAR2
    , p_file_name    IN   VARCHAR2
   )
      RETURN VARCHAR2;

   FUNCTION bpel_record_file_load (
      p_file_type          IN   VARCHAR2
    , p_file_name          IN   VARCHAR2
    , p_bpel_instance_id   IN   VARCHAR2
   )
      RETURN VARCHAR2;

   PROCEDURE xx_ce_ajb_inbound_preprocess (
      x_errbuf          OUT NOCOPY      VARCHAR2
    , x_retcode         OUT NOCOPY      NUMBER
    , p_file_type       IN              VARCHAR2
    , p_ajb_file_name   IN              VARCHAR2
    , p_batch_size      IN              NUMBER
   );

   PROCEDURE od_message (
      p_msg_type         IN   VARCHAR2
    , p_msg              IN   VARCHAR2
    , p_msg_loc          IN   VARCHAR2 DEFAULT NULL
    , p_addnl_line_len   IN   NUMBER DEFAULT 110
   );
END xx_ce_ajb_cc_recon_pkg;
/
