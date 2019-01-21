SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY XX_CN_AR_EXTRACT_PKG
AS
-- +================================================================================+
-- |                  Office Depot - Project Simplify                               |
-- |      Oracle NAIO/Office Depot/Consulting Organization                          |
-- +================================================================================+
-- | Name       : XX_CN_AR_EXTRACT                                                  |
-- |                                                                                |
-- | Description:  This procedure extracts takebacks and givebacks from AR          |
-- |                                                                                |
-- |Change Record:                                                                  |
-- |===============                                                                 |
-- |Version   Date        Author                    Remarks                         |
-- |=======   ==========  =============             ================================|
-- |DRAFT 1A 24-SEP-2007 Sarah Maria Justina     Initial draft version              |
-- |1.1      16-OCT-2007 Sarah Maria Justina     Baselined after Testing            |
-- |1.2      24-OCT-2007 Sarah Maria Justina     Incorporated Onsite TestComments   |
-- |1.3      25-OCT-2007 Sarah Maria Justina     Fixed rounding issue-Error Display |
-- |                                             and made performance fixes         |
-- |1.4      30-OCT-2007 Sarah Maria Justina     Changed error reporting            |
-- |1.5      07-NOV-2007 Hema Chikkanna          Included the logic for deriving    |
-- |                                             party site id as per onsite req    |
-- |                                             and modified log error procedure   |
-- |1.6      13-NOV-2007 Sarah Maria Justina     Changed error logging              |
-- |1.7      15-NOV-2007 Sarah Maria Justina     Fixed NOTIFY_CLAWBACK query for    |
-- |                                             Performance.                       |
-- +================================================================================+
----------------------------
--Declaring Global Constants
----------------------------
   G_PROG_APPLICATION      CONSTANT CHAR (5)      := 'XXCRM';
   G_CBK_TRX_TYPE          CONSTANT CHAR (3)      := 'CBK';
   G_GBK_TRX_TYPE          CONSTANT CHAR (3)      := 'GBK';
   G_SRC_DOC_TYPE          CONSTANT CHAR (2)      := 'AR';
   G_CUST_TRX_LINE_TYPE    CONSTANT CHAR (4)      := 'LINE';
   G_RCTT_INV_TRX_TYPE     CONSTANT CHAR (3)      := 'INV';
   G_RCTT_CM_TRX_TYPE      CONSTANT CHAR (2)      := 'CM';
   G_ACC_CLASS             CONSTANT CHAR (3)      := 'REC';
   G_YES                   CONSTANT CHAR (1)      := 'Y';
   G_NO                    CONSTANT CHAR (1)      := 'N';
   G_APPL_TYPE             CONSTANT CHAR (4)      := 'CASH';
   G_PMT_STATUS            CONSTANT CHAR (3)      := 'APP';
   
   G_USER_ID               CONSTANT NUMBER        := fnd_global.user_id();
   G_LOGIN_ID              CONSTANT NUMBER        := fnd_global.login_id();
   G_APPL_ID               CONSTANT NUMBER        := 283;
   G_REPOSITORY_ID         CONSTANT NUMBER        := 100;       
   
   G_CBK_PROG_EXECUTABLE   CONSTANT VARCHAR2 (30) := 'XX_CN_AR_EXTRACT_CLAWBACKS';
   G_GBK_PROG_EXECUTABLE   CONSTANT VARCHAR2 (30) := 'XX_CN_AR_EXTRACT_GIVEBACKS';
   G_NOTIFY_CB             CONSTANT VARCHAR2 (30) := 'AR_NOTIFY(CB)';
   G_NOTIFY_GB             CONSTANT VARCHAR2 (30) := 'AR_NOTIFY(GB)';
   G_EXTRACT_CB            CONSTANT VARCHAR2 (30) := 'AR_EXTRACT(CB)';
   G_EXTRACT_GB            CONSTANT VARCHAR2 (30) := 'AR_EXTRACT(GB)';
   G_EXTRACT_MAIN          CONSTANT VARCHAR2 (30) := 'AR_MAIN';
   G_CUST_TYPE             CONSTANT VARCHAR2 (30) := 'CONTRACT';
   G_ORDER_SOURCE          CONSTANT VARCHAR2 (30) := 'XX_CN_OE_INVOICE_SOURCE';
   G_REVENUE_TYPE          CONSTANT VARCHAR2 (30) := 'NONREVENUE';
   G_CAT_SET_NAME          CONSTANT VARCHAR2 (30) := 'Inventory';
   G_ORD_SRC_TYPE          CONSTANT VARCHAR2 (30) := 'EXTERNAL';
   G_PROG_TYPE             CONSTANT VARCHAR2(100) := 'E1004C_CustomCollections_(AR_Extract)';

----------------------------
--Declaring Global Variables
----------------------------
   gn_xfer_batch_size               NUMBER        := fnd_profile.VALUE('XX_CN_AR_BATCH_SIZE');
   gn_master_org_id                 NUMBER;
   ex_run_conv_prog_first           EXCEPTION;
   ex_invalid_cn_period_date        EXCEPTION;
   ex_invalid_ar_batch_size         EXCEPTION;
   ex_invalid_run_mode              EXCEPTION;
   ex_no_master_org_setup           EXCEPTION;
   ex_many_master_orgs_setup        EXCEPTION;
   
   CURSOR gcu_mtl_item_details (p_inventory_item_id NUMBER,p_item_master_org_id NUMBER)
      IS
         SELECT 
            segment3 AS dept_code, 
            segment4 AS class_code
           FROM mtl_item_categories a, 
                mtl_categories b, 
                mtl_category_sets c
          WHERE a.organization_id = p_item_master_org_id
            AND a.inventory_item_id = p_inventory_item_id
            AND a.category_id = b.category_id
            AND c.category_set_id = a.category_set_id
            AND c.category_set_name = G_CAT_SET_NAME;

-- +===========================================================================================================+
-- | Name        :  notify_clawbacks
-- | Description :  This procedure is used to notify clawbacks.
-- | Parameters  :  p_start_date           DATE,
-- |                p_end_date             DATE,
-- |                p_process_audit_id     NUMBER
-- +===========================================================================================================+
   PROCEDURE notify_clawbacks (
      p_start_date         DATE,
      p_end_date           DATE,
      p_process_audit_id   NUMBER
   )
   IS
      ln_trx_count          NUMBER;
      ln_clb_grace_period   NUMBER;
      ld_start_due_date     DATE;
      ld_end_due_date       DATE;
      ln_proc_audit_id      NUMBER;
      lc_message_data       VARCHAR2 (4000);
      ln_message_code       NUMBER;
      lc_errmsg             VARCHAR2 (4000);
      lc_desc               VARCHAR2 (240);
   BEGIN
   ------------------------------------------------
   --Process Audit Begin Batch for NOTIFY_CLAWBACKS
   ------------------------------------------------
      lc_desc                           := 'Notify Clawbacks from '|| p_start_date|| ' to '|| p_end_date;
      xx_cn_util_pkg.begin_batch
                                        (p_parent_proc_audit_id      => p_process_audit_id,
                                         x_process_audit_id          => ln_proc_audit_id,
                                         p_request_id                => fnd_global.conc_request_id,
                                         p_process_type              => G_NOTIFY_CB,
                                         p_description               => lc_desc  
                                        );

      xx_cn_util_pkg.WRITE              ('<<Begin NOTIFY_CLAWBACKS>>', 'LOG');
      xx_cn_util_pkg.display_log        ('<<Begin NOTIFY_CLAWBACKS>>');
      xx_cn_util_pkg.WRITE              ('NOTIFY_CLAWBACKS: Extracting clawbacks for XX_CN_NOT_TRX from period '|| p_start_date|| ' to period '|| p_end_date|| '.','LOG');
      xx_cn_util_pkg.display_log        ('NOTIFY_CLAWBACKS: Extracting clawbacks for XX_CN_NOT_TRX from period '|| p_start_date|| ' to period '|| p_end_date|| '.');
    ------------------------------------------------------------------
    -- Obtain the Clawback grace period from OIC Operating Unit Setup.
    ------------------------------------------------------------------
    SELECT clawback_grace_days
      INTO ln_clb_grace_period
      FROM cn_repositories
     WHERE application_id = G_APPL_ID;

      IF (ln_clb_grace_period IS NULL)
      THEN
         fnd_message.set_name           ('XXCRM', 'XX_OIC_0018_NO_CBK_PERIOD');
         lc_message_data                := fnd_message.get;
         xx_cn_util_pkg.DEBUG           ('NOTIFY_CLAWBACKS: '|| lc_message_data);
         xx_cn_util_pkg.display_log     ('NOTIFY_CLAWBACKS: '|| lc_message_data);
      END IF;

      ln_clb_grace_period               := NVL (ln_clb_grace_period, cn_global.cbk_grace_period);
      xx_cn_util_pkg.DEBUG              ('NOTIFY_CLAWBACKS:' || ln_clb_grace_period);
      xx_cn_util_pkg.display_log        ('NOTIFY_CLAWBACKS:' || ln_clb_grace_period);

      ld_start_due_date                 := p_start_date - ln_clb_grace_period;
      ld_end_due_date                   := p_end_date -   ln_clb_grace_period;

      xx_cn_util_pkg.DEBUG              ('NOTIFY_CLAWBACKS: Clawback Date Range:'|| ld_start_due_date|| ' to '|| ld_end_due_date);
      xx_cn_util_pkg.display_log        ('NOTIFY_CLAWBACKS: Clawback Date Range:'|| ld_start_due_date|| ' to '|| ld_end_due_date);
      --------------------------------------------------------------------------                           
      --Notify the records that qualify for Extraction into XX_CN_NOT_TRX Table
      --------------------------------------------------------------------------
      INSERT INTO xx_cn_not_trx
          (not_trx_id, 
           batch_id, 
           notified_date, 
           processed_date,
           extracted_flag, 
           row_id, 
           source_trx_id,
           source_doc_type,
           event_id, 
           process_audit_id,
           org_id, 
           last_extracted_date,
           request_id, 
           source_trx_line_id,
           program_application_id,
           created_by,
           creation_date,
           last_updated_by,
           last_update_date,
           last_update_login)
         SELECT 
            xx_cn_not_trx_s.NEXTVAL,
            FLOOR (xx_cn_not_trx_s.CURRVAL / gn_xfer_batch_size), 
            SYSDATE,
            p_end_date,
            G_NO, 
            aps.ROWID,
            aps.payment_schedule_id,
            G_SRC_DOC_TYPE,
            cn_global.cbk_event_id,
            ln_proc_audit_id, 
            aps.org_id, 
            SYSDATE,
            fnd_global.conc_request_id, 
            rctl.customer_trx_line_id,
            FND_GLOBAL.prog_appl_id,
            G_USER_ID,
            SYSDATE,
            G_USER_ID,
            SYSDATE,
            G_LOGIN_ID
           FROM (SELECT 
                   ROWID,
                   payment_schedule_id,
                   org_id,
                   customer_trx_id
                 FROM ar_payment_schedules
                 WHERE due_date BETWEEN ld_start_due_date AND ld_end_due_date
                   AND amount_line_items_remaining > 0 ) aps,
                ra_customer_trx rct,
                ra_cust_trx_types rctt,
                cn_repositories cr,
                ra_batch_sources rbs,
                ra_customer_trx_lines rctl
          WHERE 
                aps.customer_trx_id = rct.customer_trx_id
            AND rct.cust_trx_type_id = rctt.cust_trx_type_id
            AND aps.customer_trx_id = rctl.customer_trx_id
            AND rctl.line_type = G_CUST_TRX_LINE_TYPE
            AND rct.complete_flag = G_YES
            AND rctt.TYPE IN (G_RCTT_INV_TRX_TYPE, G_RCTT_CM_TRX_TYPE)
            AND rct.set_of_books_id = cr.set_of_books_id
            AND cr.repository_id = G_REPOSITORY_ID
            AND rct.batch_source_id = rbs.batch_source_id
            AND rbs.NAME IN (
                   SELECT meaning
                     FROM fnd_lookups
                    WHERE lookup_type = G_ORDER_SOURCE
                      AND enabled_flag = G_YES)
            AND NOT EXISTS (
                   SELECT 1
                     FROM xx_cn_not_trx
                    WHERE source_trx_id = aps.payment_schedule_id
                      AND event_id = cn_global.cbk_event_id)
            AND EXISTS (
                   SELECT 1
                     FROM ra_cust_trx_line_gl_dist rctlgd
                    WHERE rctlgd.customer_trx_id = rct.customer_trx_id
                      AND rctlgd.account_class = G_ACC_CLASS
                      AND rctlgd.latest_rec_flag = G_YES
                      AND rctlgd.gl_posted_date IS NOT NULL)
            AND EXISTS (
                   SELECT cust_account_id
                     FROM hz_cust_accounts hca
                    WHERE hca.cust_account_id = rct.sold_to_customer_id
                      AND hca.attribute18 = G_CUST_TYPE);

      ln_trx_count                      := SQL%ROWCOUNT;

      IF (ln_trx_count = 0)
      THEN
         fnd_message.set_name           ('XXCRM', 'XX_OIC_0008_NO_DATA_FOUND');
         lc_message_data                := fnd_message.get;
         xx_cn_util_pkg.DEBUG           ('NOTIFY_CLAWBACKS: ' || lc_message_data);
         xx_cn_util_pkg.display_log     ('NOTIFY_CLAWBACKS: ' || lc_message_data);
      END IF;

      COMMIT;
      fnd_message.set_name              ('XXCRM', 'XX_OIC_0009_CBK_ROWS_NOTIFIED');
      fnd_message.set_token             ('TRX_COUNT', ln_trx_count);
      lc_message_data                   := fnd_message.get;
      xx_cn_util_pkg.WRITE              ('NOTIFY_CLAWBACKS:' || lc_message_data, 'LOG');
      xx_cn_util_pkg.display_log        ('NOTIFY_CLAWBACKS:' || lc_message_data);
      xx_cn_util_pkg.update_batch       (ln_proc_audit_id, 0, lc_message_data);
      xx_cn_util_pkg.display_out        (' Number of clawbacks notified:              '|| LPAD(ln_trx_count,15));
      xx_cn_util_pkg.display_out        ('');
      xx_cn_util_pkg.WRITE              ('<<End NOTIFY_CLAWBACKS>>', 'LOG');
      xx_cn_util_pkg.display_log        ('<<End NOTIFY_CLAWBACKS>>');
      ----------------------------- ------------------
      --Process Audit End Batch for NOTIFY_CLAWBACKS
      -----------------------------------------------
      xx_cn_util_pkg.end_batch       (ln_proc_audit_id);
   EXCEPTION
      WHEN OTHERS
      THEN
         ROLLBACK;
         ln_message_code := -1;
         fnd_message.set_name           ('XXCRM', 'XX_OIC_0010_UNEXPECTED_ERR');
         fnd_message.set_token          ('SQL_CODE', SQLCODE);
         fnd_message.set_token          ('SQL_ERR', SQLERRM);
         lc_message_data                := fnd_message.get;
         xx_cn_util_pkg.log_error
                                        ( p_prog_name      => 'XX_CN_AR_EXTRACT.NOTIFY_CLAWBACKS',
                                          p_prog_type      => G_PROG_TYPE,
                                          p_prog_id        => FND_GLOBAL.conc_request_id,
                                          p_exception      => 'XX_CN_AR_EXTRACT.NOTIFY_CLAWBACKS',
                                          p_message        => lc_message_data,
                                          p_code           => ln_message_code,
                                          p_err_code       => 'XX_OIC_0010_UNEXPECTED_ERR'
                                        );
         lc_errmsg                          := 'Procedure: NOTIFY_CLAWBACKS: ' || lc_message_data;
         xx_cn_util_pkg.DEBUG           ('--Error:' || lc_errmsg);
         xx_cn_util_pkg.display_log     ('--Error:' || lc_errmsg);
         xx_cn_util_pkg.update_batch    (ln_proc_audit_id,SQLCODE,lc_message_data);
         xx_cn_util_pkg.WRITE           ('<<End NOTIFY_CLAWBACKS>>', 'LOG');
         xx_cn_util_pkg.display_log     ('<<End NOTIFY_CLAWBACKS>>');
         xx_cn_util_pkg.end_batch       (ln_proc_audit_id);
         app_exception.raise_exception;
   END notify_clawbacks;
-- +===========================================================================================================+
-- | Name        :  notify_givebacks
-- | Description :  This procedure is used to notify givebacks.
-- | Parameters  :  p_start_date           DATE,
-- |                p_end_date             DATE,
-- |                p_process_audit_id     NUMBER
-- +===========================================================================================================+
   PROCEDURE notify_givebacks (
      p_start_date         DATE,
      p_end_date           DATE,
      p_process_audit_id   NUMBER
   )
   IS
      ln_trx_count       NUMBER;
      ln_proc_audit_id   NUMBER;
      lc_message_data    VARCHAR2 (4000);
      ln_message_code    NUMBER;
      lc_errmsg          VARCHAR2 (4000);
      lc_desc            VARCHAR2 (240);
   BEGIN
      -------------------------------------------------
      --Process Audit Begin Batch for NOTIFY_GIVEBACKS
      -------------------------------------------------
      lc_desc                           := 'Notify Givebacks from '|| p_start_date|| ' to '|| p_end_date;
      xx_cn_util_pkg.begin_batch
                                        (p_parent_proc_audit_id      => p_process_audit_id,
                                         x_process_audit_id          => ln_proc_audit_id,
                                         p_request_id                => fnd_global.conc_request_id,
                                         p_process_type              => G_NOTIFY_GB,
                                         p_description               => lc_desc 
                                        );

      xx_cn_util_pkg.WRITE              ('<<Begin NOTIFY_GIVEBACKS>>', 'LOG');
      xx_cn_util_pkg.display_log        ('<<Begin NOTIFY_GIVEBACKS>>');
      xx_cn_util_pkg.WRITE              ('NOTIFY_GIVEBACKS: Extracting givebacks for XX_CN_NOT_TRX from period '|| p_start_date|| ' to period '|| p_end_date|| '.','LOG');
      xx_cn_util_pkg.display_log        ('NOTIFY_GIVEBACKS: Extracting givebacks for XX_CN_NOT_TRX from period '|| p_start_date|| ' to period '|| p_end_date|| '.');

      INSERT INTO xx_cn_not_trx
          (not_trx_id, 
           batch_id, 
           notified_date, 
           processed_date,
           extracted_flag, 
           row_id, 
           source_trx_id, 
           source_doc_type,
           event_id, 
           process_audit_id, 
           org_id, 
           last_extracted_date,
           request_id, 
           source_trx_line_id,
           program_application_id,
           created_by,
           creation_date,
           last_updated_by,
           last_update_date,
           last_update_login
           )
         SELECT 
            xx_cn_not_trx_s.NEXTVAL,
            FLOOR (xx_cn_not_trx_s.CURRVAL / gn_xfer_batch_size), 
            SYSDATE,
            ara.gl_date, 
            G_NO, 
            ara.ROWID, 
            ara.receivable_application_id,
            G_SRC_DOC_TYPE, 
            cn_global.gbk_event_id, 
            ln_proc_audit_id, 
            ara.org_id,
            SYSDATE, 
            fnd_global.conc_request_id,
            rctl.customer_trx_line_id,
            FND_GLOBAL.prog_appl_id,
            G_USER_ID,
            SYSDATE,
            G_USER_ID,
            SYSDATE,
            G_LOGIN_ID
           FROM ar_receivable_applications ara,
                cn_repositories cr,
                ra_customer_trx rct,
                ra_batch_sources rbs,
                ra_customer_trx_lines rctl
          WHERE ara.application_type = G_APPL_TYPE
            AND ara.status = G_PMT_STATUS
            AND ara.gl_date BETWEEN p_start_date AND p_end_date
            AND ara.gl_posted_date IS NOT NULL
            AND rct.customer_trx_id = ara.applied_customer_trx_id
            AND rct.batch_source_id = rbs.batch_source_id
            AND ara.applied_customer_trx_id = rctl.customer_trx_id
            AND rctl.line_type = G_CUST_TRX_LINE_TYPE
            AND rbs.NAME IN (
                   SELECT meaning
                     FROM fnd_lookups
                    WHERE lookup_type = G_ORDER_SOURCE
                      AND enabled_flag = G_YES)
            AND ara.set_of_books_id = cr.set_of_books_id
            AND cr.repository_id = 100
            AND NOT EXISTS (
                   SELECT 1
                     FROM xx_cn_not_trx
                    WHERE source_trx_id = ara.receivable_application_id
                      AND event_id = cn_global.gbk_event_id)
            AND EXISTS (
                   SELECT ar_trx_id
                     FROM xx_cn_ar_trx cat
                    WHERE cat.payment_schedule_id =
                                               ara.applied_payment_schedule_id
                      AND cat.trx_type = G_CBK_TRX_TYPE)
            AND EXISTS (
                   SELECT cust_account_id
                     FROM hz_cust_accounts hca
                    WHERE hca.cust_account_id = rct.sold_to_customer_id
                      AND hca.attribute18 = G_CUST_TYPE);

      ln_trx_count                     := SQL%ROWCOUNT;

      IF (ln_trx_count = 0)
      THEN
         fnd_message.set_name           ('XXCRM', 'XX_OIC_0008_NO_DATA_FOUND');
         lc_message_data                := fnd_message.get;
         xx_cn_util_pkg.DEBUG           ('NOTIFY_GIVEBACKS: ' || lc_message_data);
         xx_cn_util_pkg.display_log     ('NOTIFY_GIVEBACKS: ' || lc_message_data);
      END IF;

      COMMIT;
      fnd_message.set_name              ('XXCRM', 'XX_OIC_0011_GBK_ROWS_NOTIFIED');
      fnd_message.set_token             ('TRX_COUNT', ln_trx_count);
      lc_message_data                   := fnd_message.get;
      xx_cn_util_pkg.WRITE              ('NOTIFY_GIVEBACKS:' || lc_message_data, 'LOG');
      xx_cn_util_pkg.display_log        ('NOTIFY_GIVEBACKS:' || lc_message_data);
      xx_cn_util_pkg.update_batch       (ln_proc_audit_id, 0, lc_message_data);
      xx_cn_util_pkg.display_out        (' Number of givebacks notified:              '|| LPAD(ln_trx_count,15));
      xx_cn_util_pkg.display_out        ('');
      xx_cn_util_pkg.WRITE              ('<<End NOTIFY_GIVEBACKS>>', 'LOG');
      xx_cn_util_pkg.display_log        ('<<End NOTIFY_GIVEBACKS>>');
      -----------------------------------------------
      --Process Audit End Batch for NOTIFY_GIVEBACKS
      -----------------------------------------------
      xx_cn_util_pkg.end_batch          (ln_proc_audit_id);
   EXCEPTION
      WHEN OTHERS
      THEN
         ROLLBACK;
         ln_message_code := -1;
         fnd_message.set_name           ('XXCRM', 'XX_OIC_0010_UNEXPECTED_ERR');
         fnd_message.set_token          ('SQL_CODE', SQLCODE);
         fnd_message.set_token          ('SQL_ERR', SQLERRM);
         lc_message_data                := fnd_message.get;
         xx_cn_util_pkg.log_error
                                        (p_prog_name      => 'XX_CN_AR_EXTRACT.NOTIFY_GIVEBACKS',
                                         p_prog_type      => G_PROG_TYPE,
                                         p_prog_id        => FND_GLOBAL.conc_request_id,
                                         p_exception      => 'XX_CN_AR_EXTRACT.NOTIFY_GIVEBACKS',
                                         p_message        => lc_message_data,
                                         p_code           => ln_message_code,
                                         p_err_code       => 'XX_OIC_0010_UNEXPECTED_ERR'
                                        );
         lc_errmsg                      := 'Procedure: NOTIFY_GIVEBACKS: ' || lc_message_data;
         xx_cn_util_pkg.DEBUG           ('--Error:' || lc_errmsg);
         xx_cn_util_pkg.display_log     ('--Error:' || lc_errmsg);
         xx_cn_util_pkg.update_batch    (ln_proc_audit_id,SQLCODE,lc_message_data);
         xx_cn_util_pkg.WRITE           ('<<End NOTIFY_GIVEBACKS>>', 'LOG');
         xx_cn_util_pkg.display_log     ('<<End NOTIFY_GIVEBACKS>>');
         xx_cn_util_pkg.end_batch       (ln_proc_audit_id);
         app_exception.raise_exception;
   END notify_givebacks;
-- +===========================================================================================================+
-- | Name        :  extract_main
-- | Description :  This procedure is used to extract AR Data.
-- | Parameters  :  x_errbuf       OUT   VARCHAR2,
-- |            x_retcode      OUT   NUMBER,
-- |            p_start_date         VARCHAR2,
-- |            p_end_date           VARCHAR2,
-- |                p_mode               VARCHAR2 
-- +===========================================================================================================+
   PROCEDURE extract_main (
      x_errbuf       OUT   VARCHAR2,
      x_retcode      OUT   NUMBER,
      p_start_date         VARCHAR2 DEFAULT NULL,
      p_end_date           VARCHAR2 DEFAULT NULL,
      p_mode           VARCHAR2
   )
   IS
      ln_proc_audit_id        NUMBER;
      ln_maxwait              NUMBER                    := 0;
      ln_conc_request_id      NUMBER;
      ln_conc_req_index       NUMBER                    := 0;
      ln_message_code         NUMBER;
      ln_count                NUMBER;
      
      ld_start_date           DATE;
      ld_end_date             DATE;
      
      lb_request_status       BOOLEAN;
      
      lc_message_data         VARCHAR2 (4000);
      lc_errmsg               VARCHAR2 (4000);
      lc_phase                VARCHAR2 (100)            := NULL;
      lc_status               VARCHAR2 (100)            := NULL;
      lc_dev_phase            VARCHAR2 (100)            := NULL;
      lc_dev_status           VARCHAR2 (100)            := NULL;
      lc_message              VARCHAR2 (100)            := NULL;
      lc_desc                 VARCHAR2 (240)            := NULL;
      
      lt_conc_req_tbl         xx_conc_requests_tbl_type;
      lt_empty_conc_req_tbl   xx_conc_requests_tbl_type;

      CURSOR lcu_get_extract_stats(p_proc_audit_id NUMBER)
      IS
      SELECT   
               COUNT (*) as ext_count, 
               event_id
          FROM xx_cn_ar_trx
         WHERE process_audit_id IN (SELECT process_audit_id
                                FROM xx_cn_process_audits
                               WHERE process_audit_id = p_proc_audit_id)
      GROUP BY event_id;
      
      CURSOR lcu_batches(p_event_id NUMBER)
      IS
         SELECT DISTINCT batch_id
                    FROM xx_cn_not_trx
                   WHERE extracted_flag = 'N'
                     AND event_id = p_event_id;

   BEGIN
      -------------------------------------------------------
      -- Obtaining Dates based on Mode of Concurrent Program
      -------------------------------------------------------  
      IF p_mode = 'INTERFACE' THEN
      
         SELECT COUNT (1)
          INTO ln_count
          FROM DUAL
         WHERE EXISTS (
                  SELECT not_trx_id
                    FROM xx_cn_not_trx xcnt
                   WHERE xcnt.source_doc_type = g_src_doc_type
                     AND xcnt.event_id IN
                                     (cn_global.cbk_event_id, cn_global.gbk_event_id));
           
         SELECT MIN (start_date)
           INTO ld_start_date
           FROM cn_acc_period_statuses_v
          WHERE (quarter_num, period_year) =
                                       (SELECT quarter_num, period_year
                                          FROM cn_acc_period_statuses_v
                                        WHERE SYSDATE BETWEEN start_date AND end_date);

         ld_end_date := SYSDATE;

         IF (ln_count = 0)
         THEN
            RAISE ex_run_conv_prog_first;
         END IF;
      ELSIF p_mode ='CONVERSION' THEN
         ld_start_date                  := fnd_date.canonical_to_date(p_start_date);
         ld_end_date                    := fnd_date.canonical_to_date(p_end_date);
      ELSE 
         RAISE ex_invalid_run_mode;
      END IF;
      
      xx_cn_util_pkg.display_out        (RPAD (' Office Depot', 100)|| 'Date:'|| SYSDATE);
      xx_cn_util_pkg.display_out        (LPAD ('OD AR Extract Process',70)|| LPAD ('Page:1', 36));
      xx_cn_util_pkg.display_out        (RPAD (' ', 200, '_'));

      xx_cn_util_pkg.display_out        ('');
      xx_cn_util_pkg.display_out        ('');
      xx_cn_util_pkg.display_out        ('');
      
      xx_cn_util_pkg.display_log        ('<<Begin EXTRACT_MAIN>>');
      xx_cn_util_pkg.display_out        ( ' Mode of Run: ' || p_mode);
      xx_cn_util_pkg.display_log        ( ' Mode of Run: ' || p_mode);
      xx_cn_util_pkg.display_out        ('');
      xx_cn_util_pkg.display_out        ('');
      xx_cn_util_pkg.display_out        ('');
      lc_desc                           := 'AR Extract('||p_mode||') from '|| ld_start_date|| ' to '|| ld_end_date;
      -----------------------------------------------
      --Process Audit Begin Batch for EXTRACT_MAIN
      -----------------------------------------------
      xx_cn_util_pkg.begin_batch
                                        (p_parent_proc_audit_id      => NULL,
                                         x_process_audit_id          => ln_proc_audit_id,
                                         p_request_id                => fnd_global.conc_request_id,
                                         p_process_type              => G_EXTRACT_MAIN,
                                         p_description               => lc_desc  
                                        );

      -------------------------------------------------------
      -- Checking if Dates belong to Open/Future OIC periods
      -------------------------------------------------------
      xx_cn_util_pkg.WRITE              ('<<Begin EXTRACT_MAIN>>', 'LOG');
      xx_cn_util_pkg.DEBUG              ('EXTRACT_MAIN: Checking if dates belong to Open/Future periods');
      xx_cn_util_pkg.display_log        ('EXTRACT_MAIN: Checking if dates belong to Open/Future periods');
      xx_cn_util_pkg.display_log        ('Start Date:' || ld_start_date);
      xx_cn_util_pkg.display_log        ('End Date:'   || ld_end_date);

      SELECT COUNT (1)
        INTO ln_count
        FROM cn_acc_period_statuses_v
       WHERE ld_start_date BETWEEN start_date AND end_date;

      IF (ln_count = 0)
      THEN
         RAISE ex_invalid_cn_period_date;
      END IF;

      SELECT COUNT (1)
        INTO ln_count
        FROM cn_acc_period_statuses_v
       WHERE ld_end_date BETWEEN start_date AND end_date;

      IF (ln_count = 0)
      THEN
         RAISE ex_invalid_cn_period_date;
      END IF;
      
      -------------------------------------------------------
      -- Checking if OD: AR Batch Size profile value is valid
      -------------------------------------------------------
      BEGIN
         xx_cn_util_pkg.DEBUG           ('EXTRACT_MAIN: Checking if Batch Size from XX_CN_AR_BATCH_SIZE is valid');
         xx_cn_util_pkg.display_log     ('EXTRACT_MAIN: Checking if Batch Size from XX_CN_AR_BATCH_SIZE is valid');

         IF (gn_xfer_batch_size IS NULL OR gn_xfer_batch_size <= 0)
         THEN
            RAISE ex_invalid_ar_batch_size;
         END IF;
      EXCEPTION
         WHEN OTHERS
         THEN
            RAISE ex_invalid_ar_batch_size;
      END;

      xx_cn_util_pkg.DEBUG              ('EXTRACT_MAIN: Batch Size:'|| gn_xfer_batch_size);
      xx_cn_util_pkg.display_log        ('EXTRACT_MAIN: Batch Size:'|| gn_xfer_batch_size);

      BEGIN
      xx_cn_util_pkg.DEBUG              ('EXTRACT_MAIN: Checking if we have a valid Item Master Organization');
      xx_cn_util_pkg.display_log        ('EXTRACT_MAIN: Checking if we have a valid Item Master Organization');
      
      select organization_id 
       into gn_master_org_id
       from mtl_parameters
          where organization_id = master_organization_id;
      
      IF(gn_master_org_id is NULL) THEN
        RAISE ex_no_master_org_setup;
      END IF;
      EXCEPTION
      WHEN TOO_MANY_ROWS THEN
          RAISE ex_many_master_orgs_setup;
      END;
      
      xx_cn_util_pkg.WRITE              ('EXTRACT_MAIN: Calling Notify Clawbacks procedure','LOG');
      xx_cn_util_pkg.display_log        ('EXTRACT_MAIN: Calling Notify Clawbacks procedure');
      -------------------------------------------------------
      -- Calling notify_clawbacks
      -------------------------------------------------------
      xx_cn_util_pkg.flush;
      notify_clawbacks                  (p_start_date            => ld_start_date,
                                         p_end_date              => ld_end_date,
                                         p_process_audit_id      => ln_proc_audit_id
                                        );
      xx_cn_util_pkg.g_process_audit_id := ln_proc_audit_id;                 
      xx_cn_util_pkg.WRITE              ('EXTRACT_MAIN: Finished notification for Clawbacks','LOG');
      xx_cn_util_pkg.display_log        ('EXTRACT_MAIN: Finished notification for Clawbacks');
      xx_cn_util_pkg.WRITE              ('EXTRACT_MAIN: Start Clawback Extract', 'LOG');
      xx_cn_util_pkg.display_log        ('EXTRACT_MAIN: Start Clawback Extract');

      -------------------------------------------------------
      -- Launching Child Programs to extract Clawbacks
      -------------------------------------------------------
      FOR l_clawback_rec IN lcu_batches(cn_global.cbk_event_id)
      LOOP
         BEGIN
            xx_cn_util_pkg.flush;
            ln_conc_request_id          :=      
                                        fnd_request.submit_request
                                        (application      => g_prog_application,
                                         program          => g_cbk_prog_executable,
                                         sub_request      => FALSE,
                                         argument1        => l_clawback_rec.batch_id,
                                         argument2        => ln_proc_audit_id
                                        );
            xx_cn_util_pkg.g_process_audit_id := ln_proc_audit_id;
            COMMIT;

            IF (ln_conc_request_id = 0)
            THEN
               ROLLBACK;
               ln_message_code := -1;
               fnd_message.set_name     ('XXCRM', 'XX_OIC_0012_CONC_PRG_FAILED');
               fnd_message.set_token    ('PRG_NAME', g_cbk_prog_executable);
               fnd_message.set_token    ('SQL_CODE', SQLCODE);
               fnd_message.set_token    ('SQL_ERR', SQLERRM);
               lc_message_data              := fnd_message.get;
               xx_cn_util_pkg.log_error
                                        (p_prog_name      => 'XX_CN_AR_EXTRACT.EXTRACT_MAIN',
                                         p_prog_type      => G_PROG_TYPE,
                                         p_prog_id        => FND_GLOBAL.conc_request_id,
                                         p_exception      => 'XX_CN_AR_EXTRACT.EXTRACT_MAIN',
                                         p_message        => lc_message_data,
                                         p_code           => ln_message_code,
                                         p_err_code       => 'XX_OIC_0012_CONC_PRG_FAILED'
                                        );
               lc_errmsg                := 'Procedure: EXTRACT_MAIN: ' || lc_message_data;
               xx_cn_util_pkg.DEBUG     ('--Error:' || lc_errmsg);
               xx_cn_util_pkg.display_log
                                        ('--Error:' || lc_errmsg);
               x_retcode                := 1;
               x_errbuf                 := 'Procedure: EXTRACT_MAIN: ' || lc_message_data;
            ELSE
               lt_conc_req_tbl(ln_conc_req_index) 
                                        := ln_conc_request_id;
               xx_cn_util_pkg.DEBUG     ('Submitted the child conc program '|| g_cbk_prog_executable);
               xx_cn_util_pkg.display_log
                                        ('Submitted the child conc program '|| g_cbk_prog_executable);
               xx_cn_util_pkg.DEBUG     ('Concurrent Request ID: '|| ln_conc_request_id);
               xx_cn_util_pkg.display_log
                                        ('Concurrent Request ID: '|| ln_conc_request_id);
            END IF;
            ln_conc_req_index           := ln_conc_req_index + 1;
         END;
      END LOOP;
      ------------------------------------------------------------------
      -- Waiting for all the Extract Clawback Child Programs to Complete
      ------------------------------------------------------------------
      IF (ln_conc_req_index > 0)
      THEN
         FOR i IN 0 .. (ln_conc_req_index - 1)
         LOOP
            ln_conc_request_id          := lt_conc_req_tbl (i);
            lb_request_status           :=fnd_concurrent.wait_for_request
                                        (request_id      => ln_conc_request_id,
                                         INTERVAL        => 10,
                                         max_wait        => ln_maxwait,
                                         -- Wait indefinitely.
                                         phase           => lc_phase,
                                         status          => lc_status,
                                         dev_phase       => lc_dev_phase,
                                         dev_status      => lc_dev_status,
                                         MESSAGE         => lc_message
                                         );

            IF (   lc_dev_status = 'ERROR'
                OR lc_dev_status = 'TERMINATED'
                OR lc_dev_status = 'CANCELLED'
               )
            THEN
               x_retcode                := 1;
               x_errbuf                 := 'Procedure: EXTRACT_MAIN: ' || lc_message;
            END IF;
         END LOOP;
      END IF;

      xx_cn_util_pkg.WRITE              ('EXTRACT_MAIN: End Clawback Extract', 'LOG');
      xx_cn_util_pkg.display_log        ('EXTRACT_MAIN: End Clawback Extract');
      
      ------------------------------------------------------------------
      -- Initializing the concurrent program PL/SQL Table 
      ------------------------------------------------------------------
      ln_conc_req_index                 := 0;
      lt_conc_req_tbl                   := lt_empty_conc_req_tbl;
      xx_cn_util_pkg.WRITE              ('EXTRACT_MAIN: Calling Notify Givebacks procedure','LOG');
      xx_cn_util_pkg.display_log        ('EXTRACT_MAIN: Calling Notify Givebacks procedure');
      -------------------------------------------------------
      -- Calling notify_givebacks
      -------------------------------------------------------
      xx_cn_util_pkg.flush;
      notify_givebacks                  (p_start_date            => ld_start_date,
                                         p_end_date              => ld_end_date,
                                         p_process_audit_id      => ln_proc_audit_id
                                        );
      xx_cn_util_pkg.g_process_audit_id := ln_proc_audit_id;                
      xx_cn_util_pkg.WRITE              ('EXTRACT_MAIN: Finished notification for Givebacks','LOG');
      xx_cn_util_pkg.display_log        ('EXTRACT_MAIN: Finished notification for Givebacks');
      xx_cn_util_pkg.WRITE              ('EXTRACT_MAIN: Start Givebacks Extract', 'LOG');
      xx_cn_util_pkg.display_log        ('EXTRACT_MAIN: Start Givebacks Extract');
      -------------------------------------------------------
      -- Launching Child Programs to extract Givebacks
      -------------------------------------------------------
      FOR l_giveback_rec IN lcu_batches (cn_global.gbk_event_id)
      LOOP
         BEGIN
            xx_cn_util_pkg.flush;
            ln_conc_request_id          := 
                                        fnd_request.submit_request
                                        (application      => g_prog_application,
                                         program          => g_gbk_prog_executable,
                                         sub_request      => FALSE,
                                         argument1        => l_giveback_rec.batch_id,
                                         argument2        => ln_proc_audit_id
                                        );
            xx_cn_util_pkg.g_process_audit_id := ln_proc_audit_id;
            COMMIT;

            IF (ln_conc_request_id = 0)
            THEN
               ROLLBACK;
               ln_message_code := -1;
               fnd_message.set_name      ('XXCRM', 'XX_OIC_0012_CONC_PRG_FAILED');
               fnd_message.set_token     ('PRG_NAME', g_gbk_prog_executable);
               fnd_message.set_token     ('SQL_CODE', SQLCODE);
               fnd_message.set_token     ('SQL_ERR', SQLERRM);
               lc_message_data           := fnd_message.get;
               xx_cn_util_pkg.log_error
                                         (p_prog_name      => 'XX_CN_AR_EXTRACT.EXTRACT_MAIN',
                                          p_prog_type      => G_PROG_TYPE,
                                          p_prog_id        => FND_GLOBAL.conc_request_id,
                                          p_exception      => 'XX_CN_AR_EXTRACT.EXTRACT_MAIN',
                                          p_message        => lc_message_data,
                                          p_code           => ln_message_code,
                                          p_err_code       => 'XX_OIC_0012_CONC_PRG_FAILED'
                                         );
               lc_errmsg                 := 'Procedure: EXTRACT_MAIN: ' || lc_message_data;
               xx_cn_util_pkg.DEBUG      ('--Error:' || lc_errmsg);
               xx_cn_util_pkg.display_log
                                        ('--Error:' || lc_errmsg);
               x_retcode                := 1;
               x_errbuf                 := 'Procedure: EXTRACT_MAIN: ' || lc_message_data;
            ELSE
               lt_conc_req_tbl (ln_conc_req_index) 
                                        := ln_conc_request_id;
               xx_cn_util_pkg.DEBUG     ('Submitted the child conc program '|| g_gbk_prog_executable);
               xx_cn_util_pkg.display_log
                                        ('Submitted the child conc program '|| g_gbk_prog_executable);
               xx_cn_util_pkg.DEBUG     ('Concurrent Request ID: '|| ln_conc_request_id);
               xx_cn_util_pkg.display_log
                                        ('Concurrent Request ID: '|| ln_conc_request_id);
            END IF;
            ln_conc_req_index           := ln_conc_req_index + 1;
         END;
      END LOOP;
      ------------------------------------------------------------------
      -- Waiting for all the Extract Giveback Child Programs to Complete
      ------------------------------------------------------------------
      IF (ln_conc_req_index > 0)
      THEN
         FOR i IN 0 .. (ln_conc_req_index - 1)
         LOOP
            ln_conc_request_id          := lt_conc_req_tbl (i);
            lb_request_status           := fnd_concurrent.wait_for_request
                                        (request_id      => ln_conc_request_id,
                                         INTERVAL        => 10,
                                         max_wait        => ln_maxwait,
                                         -- Wait indefinitely.
                                         phase           => lc_phase,
                                         status          => lc_status,
                                         dev_phase       => lc_dev_phase,
                                         dev_status      => lc_dev_status,
                                         MESSAGE         => lc_message
                                         );

            IF (   lc_dev_status = 'ERROR'
                OR lc_dev_status = 'TERMINATED'
                OR lc_dev_status = 'CANCELLED'
               )
            THEN
               x_retcode                 := 1;
               x_errbuf                  := 'Procedure: EXTRACT_MAIN: ' || lc_message;
            END IF;
         END LOOP;
      END IF;

      xx_cn_util_pkg.WRITE              ('EXTRACT_MAIN: End Giveback Extract', 'LOG');
      xx_cn_util_pkg.display_log        ('EXTRACT_MAIN: End Giveback Extract');
      
      FOR l_extract_stats in lcu_get_extract_stats(ln_proc_audit_id)
      LOOP
      IF(l_extract_stats.event_id=-1008) THEN
        xx_cn_util_pkg.display_out      (   ' Number of clawbacks extracted:             '||LPAD(l_extract_stats.ext_count,15));
        xx_cn_util_pkg.display_out      ('');
      ELSIF
      (l_extract_stats.event_id=-1006) THEN
        xx_cn_util_pkg.display_out      (   ' Number of givebacks extracted:             '||LPAD(l_extract_stats.ext_count,15));
        xx_cn_util_pkg.display_out      ('');
      END IF;
      END LOOP;
      
      xx_cn_util_pkg.display_out        (   ' Please check the Worker Requests that have Completed with Warning if the notified and extracted number of records differ.');
      xx_cn_util_pkg.display_out        (RPAD (' ', 200, '_'));
      xx_cn_util_pkg.update_batch       (ln_proc_audit_id,0,'Finished AR Master Program');
      xx_cn_util_pkg.WRITE              ('<<End EXTRACT_MAIN>>', 'LOG');
      xx_cn_util_pkg.display_log        ('<<End EXTRACT_MAIN>>');
      -----------------------------------------------
      --Process Audit End Batch for EXTRACT_MAIN
      -----------------------------------------------
      xx_cn_util_pkg.end_batch          (ln_proc_audit_id);
   EXCEPTION
      WHEN ex_no_master_org_setup
      THEN
         ROLLBACK;
         ln_message_code                := -1;
         fnd_message.set_name           ('XXCRM', 'XX_OIC_0022_NO_MASTER_ORG');
         lc_message_data                := fnd_message.get;
         xx_cn_util_pkg.log_error
                                        (p_prog_name      => 'XX_CN_AR_EXTRACT.EXTRACT_MAIN',
                                         p_prog_type      => G_PROG_TYPE,
                                         p_prog_id        => FND_GLOBAL.conc_request_id,
                                         p_exception      => 'XX_CN_AR_EXTRACT.EXTRACT_MAIN',
                                         p_message        => lc_message_data,
                                         p_code           => ln_message_code,
                                         p_err_code       => 'XX_OIC_0022_NO_MASTER_ORG'
                                        );
         lc_errmsg                      := 'Procedure: EXTRACT_MAIN: ' || lc_message_data;
         xx_cn_util_pkg.DEBUG           ('--Error:' || lc_errmsg);
         xx_cn_util_pkg.display_log     ('--Error:' || lc_errmsg);
         xx_cn_util_pkg.update_batch    (ln_proc_audit_id, 0, lc_message_data);
         xx_cn_util_pkg.WRITE           ('<<End EXTRACT_MAIN>>', 'LOG');
         xx_cn_util_pkg.display_log     ('<<End EXTRACT_MAIN>>');
         xx_cn_util_pkg.end_batch       (ln_proc_audit_id);
         x_retcode                      := 2;
         x_errbuf                       := 'Procedure: EXTRACT_MAIN: ' || lc_message_data;
      WHEN ex_many_master_orgs_setup
      THEN
         ROLLBACK;
         ln_message_code                := -1;
         fnd_message.set_name           ('XXCRM', 'XX_OIC_0023_MANY_MASTER_ORG');
         lc_message_data                := fnd_message.get;
         xx_cn_util_pkg.log_error
                                        (p_prog_name      => 'XX_CN_AR_EXTRACT.EXTRACT_MAIN',
                                         p_prog_type      => G_PROG_TYPE,
                                         p_prog_id        => FND_GLOBAL.conc_request_id,
                                         p_exception      => 'XX_CN_AR_EXTRACT.EXTRACT_MAIN',
                                         p_message        => lc_message_data,
                                         p_code           => ln_message_code,
                                         p_err_code       => 'XX_OIC_0023_MANY_MASTER_ORG'
                                        );
         lc_errmsg                      := 'Procedure: EXTRACT_MAIN: ' || lc_message_data;
         xx_cn_util_pkg.DEBUG           ('--Error:' || lc_errmsg);
         xx_cn_util_pkg.display_log     ('--Error:' || lc_errmsg);
         xx_cn_util_pkg.update_batch    (ln_proc_audit_id, 0, lc_message_data);
         xx_cn_util_pkg.WRITE           ('<<End EXTRACT_MAIN>>', 'LOG');
         xx_cn_util_pkg.display_log     ('<<End EXTRACT_MAIN>>');
         xx_cn_util_pkg.end_batch       (ln_proc_audit_id);
         x_retcode                      := 2;
         x_errbuf                       := 'Procedure: EXTRACT_MAIN: ' || lc_message_data;
      WHEN ex_invalid_run_mode
      THEN
         ROLLBACK;
         ln_message_code                := -1;
         fnd_message.set_name           ('XXCRM', 'XX_OIC_0020_INVALID_MODE');
         lc_message_data                := fnd_message.get;
         xx_cn_util_pkg.log_error
                                        (p_prog_name      => 'XX_CN_AR_EXTRACT.EXTRACT_MAIN',
                                         p_prog_type      => G_PROG_TYPE,
                                         p_prog_id        => FND_GLOBAL.conc_request_id,
                                         p_exception      => 'XX_CN_AR_EXTRACT.EXTRACT_MAIN',
                                         p_message        => lc_message_data,
                                         p_code           => ln_message_code,
                                         p_err_code       => 'XX_OIC_0020_INVALID_MODE'
                                        );
         lc_errmsg                       := 'Procedure: EXTRACT_MAIN: ' || lc_message_data;
         xx_cn_util_pkg.display_log     ('--Error:' || lc_errmsg);
         xx_cn_util_pkg.WRITE           ('<<End EXTRACT_MAIN>>', 'LOG');
         xx_cn_util_pkg.display_log     ('<<End EXTRACT_MAIN>>');
         x_retcode                      := 2;
         x_errbuf                       := 'Procedure: EXTRACT_MAIN: ' || lc_message_data;
      WHEN ex_run_conv_prog_first
      THEN
         ROLLBACK;
         ln_message_code                := -1;
         fnd_message.set_name           ('XXCRM', 'XX_OIC_0013_RUN_CONV_FIRST');
         lc_message_data                := fnd_message.get;
         xx_cn_util_pkg.log_error
                                        (p_prog_name      => 'XX_CN_AR_EXTRACT.EXTRACT_MAIN',
                                         p_prog_type      => G_PROG_TYPE,
                                         p_prog_id        => FND_GLOBAL.conc_request_id,
                                         p_exception      => 'XX_CN_AR_EXTRACT.EXTRACT_MAIN',
                                         p_message        => lc_message_data,
                                         p_code           => ln_message_code,
                                         p_err_code       => 'XX_OIC_0013_RUN_CONV_FIRST'
                                        );
         lc_errmsg                       := 'Procedure: EXTRACT_MAIN: ' || lc_message_data;
         xx_cn_util_pkg.display_log     ('--Error:' || lc_errmsg);
         xx_cn_util_pkg.WRITE           ('<<End EXTRACT_MAIN>>', 'LOG');
         xx_cn_util_pkg.display_log     ('<<End EXTRACT_MAIN>>');
         x_retcode                       := 2;
         x_errbuf                        := 'Procedure: EXTRACT_MAIN: ' || lc_message_data;
      WHEN ex_invalid_cn_period_date
      THEN
         ROLLBACK;
         ln_message_code                := -1;
         fnd_message.set_name           ('XXCRM', 'XX_OIC_0014_INVALID_CN_DATE');
         lc_message_data                := fnd_message.get;
         xx_cn_util_pkg.log_error
                                        (p_prog_name      => 'XX_CN_AR_EXTRACT.EXTRACT_MAIN',
                                         p_prog_type      => G_PROG_TYPE,
                                         p_prog_id        => FND_GLOBAL.conc_request_id,
                                         p_exception      => 'XX_CN_AR_EXTRACT.EXTRACT_MAIN',
                                         p_message        => lc_message_data,
                                         p_code           => ln_message_code,
                                         p_err_code       => 'XX_OIC_0014_INVALID_CN_DATE'
                                        );
         lc_errmsg                      := 'Procedure: EXTRACT_MAIN: ' || lc_message_data;
         xx_cn_util_pkg.DEBUG           ('--Error:' || lc_errmsg);
         xx_cn_util_pkg.display_log     ('--Error:' || lc_errmsg);
         xx_cn_util_pkg.update_batch    (ln_proc_audit_id, 0, lc_message_data);
         xx_cn_util_pkg.WRITE           ('<<End EXTRACT_MAIN>>', 'LOG');
         xx_cn_util_pkg.display_log     ('<<End EXTRACT_MAIN>>');
         xx_cn_util_pkg.end_batch       (ln_proc_audit_id);
         x_retcode                      := 2;
         x_errbuf                       := 'Procedure: EXTRACT_MAIN: ' || lc_message_data;
      WHEN ex_invalid_ar_batch_size
      THEN
         ROLLBACK;
         ln_message_code                := -1;
         fnd_message.set_name           ('XXCRM', 'XX_OIC_0015_INVALID_AR_SIZE');
         lc_message_data                := fnd_message.get;
         xx_cn_util_pkg.log_error
                                        (p_prog_name      => 'XX_CN_AR_EXTRACT.EXTRACT_MAIN',
                                         p_prog_type      => G_PROG_TYPE,
                                         p_prog_id        => FND_GLOBAL.conc_request_id,
                                         p_exception      => 'XX_CN_AR_EXTRACT.EXTRACT_MAIN',
                                         p_message        => lc_message_data,
                                         p_code           => ln_message_code,
                                         p_err_code       => 'XX_OIC_0015_INVALID_AR_SIZE'
                                        );
         lc_errmsg                      := 'Procedure: EXTRACT_MAIN: ' || lc_message_data;
         xx_cn_util_pkg.DEBUG           ('--Error:' || lc_errmsg);
         xx_cn_util_pkg.display_log     ('--Error:' || lc_errmsg);
         xx_cn_util_pkg.update_batch    (ln_proc_audit_id, 0, lc_message_data);
         xx_cn_util_pkg.WRITE           ('<<End EXTRACT_MAIN>>', 'LOG');
         xx_cn_util_pkg.display_log     ('<<End EXTRACT_MAIN>>');
         xx_cn_util_pkg.end_batch       (ln_proc_audit_id);
         x_retcode                      := 2;
         x_errbuf                       := 'Procedure: EXTRACT_MAIN: ' || lc_message_data;
      WHEN OTHERS
      THEN
         ROLLBACK;
         ln_message_code                := -1;
         fnd_message.set_name           ('XXCRM', 'XX_OIC_0010_UNEXPECTED_ERR');
         fnd_message.set_token          ('SQL_CODE', SQLCODE);
         fnd_message.set_token          ('SQL_ERR', SQLERRM);
         lc_message_data                := fnd_message.get;
         xx_cn_util_pkg.log_error
                                        (p_prog_name      => 'XX_CN_AR_EXTRACT.EXTRACT_MAIN',
                                         p_prog_type      => G_PROG_TYPE,
                                         p_prog_id        => FND_GLOBAL.conc_request_id,
                                         p_exception      => 'XX_CN_AR_EXTRACT.EXTRACT_MAIN',
                                         p_message        => lc_message_data,
                                         p_code           => ln_message_code,
                                         p_err_code       => 'XX_OIC_0010_UNEXPECTED_ERR'
                                        );
         lc_errmsg                      := 'Procedure: EXTRACT_MAIN: ' || lc_message_data;
         xx_cn_util_pkg.DEBUG           ('--Error:' || lc_errmsg);
         xx_cn_util_pkg.display_log     ('--Error:' || lc_errmsg);
         xx_cn_util_pkg.update_batch    (ln_proc_audit_id,SQLCODE,lc_message_data);
         xx_cn_util_pkg.WRITE           ('<<End EXTRACT_MAIN>>', 'LOG');
         xx_cn_util_pkg.display_log     ('<<End EXTRACT_MAIN>>');
         xx_cn_util_pkg.end_batch       (ln_proc_audit_id);
         x_retcode                      := 2;
         x_errbuf                       := 'Procedure: EXTRACT_MAIN: ' || lc_message_data;
   END extract_main;
-- +===========================================================================================================+
-- | Name        :  extract_clawbacks
-- | Description :  This procedure is used to extract AR Clawback Data.
-- | Parameters  :  x_errbuf       OUT   VARCHAR2,
-- |                x_retcode      OUT   NUMBER,
-- |                p_batch_id           NUMBER,
-- |                p_process_audit_id   NUMBER
-- +===========================================================================================================+
   PROCEDURE extract_clawbacks (
      x_errbuf             OUT   VARCHAR2,
      x_retcode            OUT   NUMBER,
      p_batch_id                 NUMBER,
      p_process_audit_id         NUMBER
   )
   IS
      ln_proc_audit_id       NUMBER;
      ln_rev_class           NUMBER;
      ln_message_code        NUMBER;
      ln_trx_count           NUMBER;
      ln_success_idx         NUMBER;
      ln_failure_idx         NUMBER;
      ln_null_rev_class      NUMBER;
      ln_null_div            NUMBER;
      ln_null_priv_band      NUMBER;
      ln_null_po_cost        NUMBER;
      ln_null_rollup_date    NUMBER;
      ln_null_trx_amt        NUMBER;
      ln_null_qty            NUMBER;
    
      L_LIMIT_SIZE           CONSTANT PLS_INTEGER               := 10000;
    
      lc_dept_code           xx_cn_ar_trx.department_code%TYPE;
      lc_class_code          xx_cn_ar_trx.class_code%TYPE;
      lc_orig_order_source   xx_cn_ar_trx.original_order_source%TYPE;
      lc_division            xx_cn_ar_trx.division%TYPE;
      lc_private_brand       xx_cn_ar_trx.private_brand%TYPE;
      
      lc_message_data        VARCHAR2 (4000); 
      lc_errmsg              VARCHAR2 (4000);
      lc_desc                VARCHAR2 (240);
      lc_err_reason          VARCHAR2 (4000);
      
      lt_ar_tbl_type         xx_ar_tbl_type;
      lt_ar_success_tbl_type xx_ar_tbl_type;
      lt_ar_failure_tbl_type xx_ar_tbl_type;
      lt_error_tbl_type      xx_error_tbl_type;

      CURSOR lcu_ar_cbk_data
      IS
      SELECT xx_cn_ar_trx_s.NEXTVAL,CBK.* 
        FROM 
       (SELECT  
        NULL AS booked_date,
        NULL AS order_date, 
        NULL AS salesrep_id,
        rct.sold_to_customer_id AS customer_id,
        rctl.inventory_item_id, 
        rct.ct_reference AS order_number,
        rctl.line_number,
        (SELECT header_id
           FROM oe_order_headers_all
         WHERE order_number = rct.ct_reference
           AND org_id = rct.org_id) AS order_header_id,
        rctl.interface_line_attribute6 AS order_line_id,
        rct.trx_number AS invoice_number,
        rct.trx_date AS invoice_date, 
        cnt.processed_date,
        (SELECT cp.period_id
          FROM cn_acc_period_statuses_v cp
         WHERE cnt.processed_date
          BETWEEN cp.start_date AND cp.end_date) AS processed_period_id,
        rct.org_id AS org_id, 
        cn_global.cbk_event_id AS event_id,
        G_REVENUE_TYPE AS revenue_type,
        (SELECT cust_acct_site_id
          FROM hz_cust_site_uses_all
         WHERE site_use_id = rct.ship_to_site_use_id) AS ship_to_address_id,
        (SELECT a.party_site_id
           FROM hz_cust_acct_sites_all a,
                hz_cust_site_uses_all  b   
         WHERE  a.cust_acct_site_id = b.cust_acct_site_id
           AND  b.site_use_id       = rct.ship_to_site_use_id       -- Included derivation of party_site_id as per table design change
           AND  a.org_id            = rct.org_id) AS party_site_id, -- Changes made on 7-Nov-2007
        rct.ship_date_actual AS rollup_date, 
        G_SRC_DOC_TYPE,
        rct.customer_trx_id, 
        rctl.customer_trx_line_id,
        rct.trx_number, 
        aps.payment_schedule_id,
        NULL AS receivable_application_id,
        NVL (rctl.quantity_invoiced, 0) AS quantity,
        (rctl.extended_amount / aps.amount_line_items_original)* aps.amount_line_items_remaining AS amount,
        rct.invoice_currency_code, 
        G_CBK_TRX_TYPE AS trx_type,
        NULL AS class_code, 
        NULL AS dept_code,
        (SELECT od_private_brand_flg
          FROM xx_inv_item_master_attributes
         WHERE inventory_item_id = rctl.inventory_item_id),
        (SELECT po_cost
          FROM xx_om_line_attributes_all
         WHERE line_id = rctl.interface_line_attribute6),
        NULL AS division, 
        NULL AS revenue_class_id,
        (CASE (SELECT source_type_code
          FROM oe_order_lines_all
         WHERE line_id = rctl.interface_line_attribute6)
         WHEN G_ORD_SRC_TYPE THEN G_YES
          ELSE G_NO END )AS drop_ship_flag, 
        NULL AS margin,
        NULL AS discount_percentage, 
        rct.exchange_rate,
        NULL AS return_reason_code,
        (SELECT NAME
          FROM oe_order_sources
         WHERE order_source_id =
           (SELECT order_source_id
              FROM oe_order_headers_all
            WHERE order_number = rct.ct_reference
              AND org_id = rct.org_id)) AS original_order_source,
        G_NO AS summarized_flag, 
        G_NO AS salesrep_assign_flag,
        cnt.batch_id,
        NULL as trnsfr_batch_id,
        NULL as summ_batch_id,
        p_process_audit_id, 
        fnd_global.conc_request_id,
        FND_GLOBAL.prog_appl_id AS program_application_id,
        TO_NUMBER (fnd_global.user_id) AS created_by,
        SYSDATE AS creation_date,
        TO_NUMBER (fnd_global.user_id) AS last_updated_by,
        SYSDATE AS last_update_date,
        TO_NUMBER (fnd_global.login_id) AS last_update_login
        FROM xx_cn_not_trx cnt,
             ar_payment_schedules aps,
             ra_customer_trx rct,
             ra_customer_trx_lines rctl,
             ra_batch_sources rbs
        WHERE cnt.source_trx_id = aps.payment_schedule_id
            AND cnt.source_trx_line_id = rctl.customer_trx_line_id
            AND rct.customer_trx_id = aps.customer_trx_id
            AND rct.org_id = fnd_global.org_id
            AND NOT EXISTS (
                   SELECT ar_trx_id
                     FROM xx_cn_ar_trx
                    WHERE payment_schedule_id = aps.payment_schedule_id
                      AND source_trx_line_id = rctl.customer_trx_line_id
                      AND trx_type = G_CBK_TRX_TYPE
                      AND rownum > 0 )
            AND cnt.event_id = cn_global.cbk_event_id
            AND cnt.extracted_flag = G_NO
            AND aps.customer_trx_id = rctl.customer_trx_id
            AND rctl.line_type = G_CUST_TRX_LINE_TYPE
            AND rct.batch_source_id = rbs.batch_source_id
            AND rbs.NAME IN (
                   SELECT meaning
                     FROM fnd_lookups
                    WHERE lookup_type = G_ORDER_SOURCE
                      AND enabled_flag = G_YES)
            AND EXISTS (
                   SELECT cust_account_id
                     FROM hz_cust_accounts hca
                    WHERE hca.cust_account_id = rct.sold_to_customer_id
                      AND hca.attribute18 = G_CUST_TYPE
                      AND rownum > 0 )
            AND cnt.batch_id = p_batch_id
            AND rownum > 0 
        ORDER BY rct.sold_to_customer_id,
                 rct.trx_number,
                 rctl.line_number) CBK;
   BEGIN
      lc_desc                           := 'Extract Clawbacks for Batch:'|| p_batch_id;
      -------------------------------------------------
      --Process Audit Begin Batch for EXTRACT_CLAWBACKS
      -------------------------------------------------
      xx_cn_util_pkg.begin_batch
                                        (p_parent_proc_audit_id      => p_process_audit_id,
                                         x_process_audit_id          => ln_proc_audit_id,
                                         p_request_id                => fnd_global.conc_request_id,
                                         p_process_type              => G_EXTRACT_CB,
                                         p_description               => lc_desc   
                                        );
      xx_cn_util_pkg.display_out        (RPAD (' Office Depot', 100)|| 'Date:'|| SYSDATE);
      xx_cn_util_pkg.display_out        (LPAD('OD AR Extract Clawbacks Child program',70)|| LPAD ('Page:1', 36));
      xx_cn_util_pkg.display_out        (RPAD (' ', 330, '_'));

      xx_cn_util_pkg.display_out        ('');
      xx_cn_util_pkg.display_out        ('');
      xx_cn_util_pkg.display_out        ('');

      xx_cn_util_pkg.WRITE              ('<<Begin EXTRACT_CLAWBACKS>>', 'LOG');
      xx_cn_util_pkg.display_log        ('<<Begin EXTRACT_MAIN>>');
      xx_cn_util_pkg.DEBUG              ('EXTRACT_CLAWBACKS: Batch Size:'|| gn_xfer_batch_size);
      xx_cn_util_pkg.display_log        ('EXTRACT_CLAWBACKS: Batch Size:'|| gn_xfer_batch_size);

      select organization_id 
       into gn_master_org_id
       from mtl_parameters
      where organization_id = master_organization_id;
      
      xx_cn_util_pkg.DEBUG              ('EXTRACT_CLAWBACKS: Before inserting data into XX_CN_AR_TRX');
      xx_cn_util_pkg.display_log        ('EXTRACT_CLAWBACKS: Before inserting data into XX_CN_AR_TRX');
      xx_cn_util_pkg.display_out        (' Batch ID                                          :              '||LPAD(p_batch_id,15));
      xx_cn_util_pkg.display_out        ('');
      -----------------------------------------------
      --Begin loop for BULK Insert
      -----------------------------------------------
      ln_trx_count := 0;
      OPEN lcu_ar_cbk_data;
      LOOP
         -------------------------------------------------
         --Initializing table types and their indexes
         -------------------------------------------------
         lt_ar_tbl_type.DELETE;
         lt_ar_success_tbl_type.DELETE;
         ln_success_idx := 0;
         lt_ar_failure_tbl_type.DELETE;
         ln_failure_idx := 0;
         lt_error_tbl_type.DELETE;
         ln_null_rev_class  := 0;     
         ln_null_div        := 0;         
         ln_null_priv_band  := 0;     
         ln_null_po_cost    := 0;      
         ln_null_rollup_date:= 0;  
         ln_null_trx_amt    := 0;     
         ln_null_qty        := 0;    
         FETCH lcu_ar_cbk_data
         BULK COLLECT INTO lt_ar_tbl_type LIMIT L_LIMIT_SIZE;

      --------------------------------------------------------------------
      --Obtaining Dept, Class, Division and Revenue class for each record
      --------------------------------------------------------------------
      IF(lt_ar_tbl_type.COUNT > 0) THEN
      FOR idx IN lt_ar_tbl_type.FIRST .. lt_ar_tbl_type.LAST
      LOOP
         IF(lt_ar_tbl_type (idx).private_brand IS NOT NULL) THEN
         OPEN gcu_mtl_item_details (lt_ar_tbl_type (idx).inventory_item_id,gn_master_org_id);

         FETCH gcu_mtl_item_details
          INTO lt_ar_tbl_type (idx).department_code,
               lt_ar_tbl_type (idx).class_code;
         CLOSE gcu_mtl_item_details;

         xx_cn_util_pkg.xx_cn_get_division
                                        (p_dept_code           => lt_ar_tbl_type (idx).department_code,
                                         p_class_code          => lt_ar_tbl_type (idx).class_code,
                                         p_order_source        => lt_ar_tbl_type (idx).original_order_source,
                                         p_collect_source      => NULL,
                                         p_private_brand       => lt_ar_tbl_type (idx).private_brand,
                                         x_division            => lt_ar_tbl_type (idx).division,
                                         x_rev_class_id        => lt_ar_tbl_type (idx).revenue_class_id
                                        );
         END IF;

         IF(lt_ar_tbl_type (idx).revenue_class_id is NOT NULL 
            AND lt_ar_tbl_type (idx).division IS NOT NULL
            AND lt_ar_tbl_type (idx).private_brand IS NOT NULL
            AND lt_ar_tbl_type (idx).cost IS NOT NULL
            AND lt_ar_tbl_type (idx).rollup_date IS NOT NULL
            AND lt_ar_tbl_type (idx).transaction_amount IS NOT NULL
            AND lt_ar_tbl_type (idx).quantity IS NOT NULL)
           THEN
               --------------------------------------------------------------------
               --Inserting success records into LT_AR_SUCCESS_TBL_TYPE
               --------------------------------------------------------------------
               lt_ar_success_tbl_type(ln_success_idx) := lt_ar_tbl_type (idx);
               ln_success_idx := ln_success_idx +1;
         ELSE
               --------------------------------------------------------------------
               --Inserting failure records into LT_AR_FAILURE_TBL_TYPE for reporting
               --------------------------------------------------------------------         
               
               lt_ar_failure_tbl_type(ln_failure_idx) := lt_ar_tbl_type (idx);
               lc_err_reason := ''; 
               IF(lt_ar_tbl_type (idx).revenue_class_id is NULL) THEN
                    lc_err_reason := 'Null REVENUE CLASS.'; 
                    ln_null_rev_class := ln_null_rev_class + 1;
               END IF;
               IF(lt_ar_tbl_type (idx).division IS NULL) THEN
                    lc_err_reason := lc_err_reason||'Null DIVISION.'; 
                    ln_null_div := ln_null_div + 1;
               END IF;
               IF(lt_ar_tbl_type (idx).private_brand IS NULL) THEN
                    lc_err_reason := lc_err_reason||'Null PRIVATE BRAND.';
                    ln_null_priv_band := ln_null_priv_band + 1;
               END IF;
               IF(lt_ar_tbl_type (idx).cost IS NULL) THEN
                    lc_err_reason := lc_err_reason||'Null PO COST.';
                    ln_null_po_cost := ln_null_po_cost + 1;
               END IF;
               IF(lt_ar_tbl_type (idx).rollup_date IS NULL) THEN
                    lc_err_reason := lc_err_reason||'Null ROLLUP DATE.';
                    ln_null_rollup_date := ln_null_rollup_date + 1;
               END IF;
               IF(lt_ar_tbl_type (idx).transaction_amount IS NULL) THEN
                    lc_err_reason := lc_err_reason||'Null TRANSACTION AMOUNT.';
                    ln_null_trx_amt := ln_null_trx_amt + 1;
               END IF;
               IF(lt_ar_tbl_type (idx).quantity IS NULL) THEN
                    lc_err_reason := lc_err_reason||'Null QUANTITY.';
                    ln_null_qty := ln_null_qty + 1;
               END IF;
               lt_error_tbl_type(ln_failure_idx) := lc_err_reason;
               ln_failure_idx := ln_failure_idx +1;
               
               lc_err_reason := 'Invoice Number:'||lt_ar_tbl_type (idx).invoice_number||
                                ' Invoice Line:'||lt_ar_tbl_type (idx).line_number|| 
                                ' Line ID:'||lt_ar_tbl_type (idx).source_trx_line_id|| 
                                ' '||lc_err_reason;  
               xx_cn_util_pkg.log_error
               (p_prog_name      => 'XX_CN_AR_EXTRACT.EXTRACT_CLAWBACKS',
                p_prog_type      => G_PROG_TYPE,
                p_prog_id        => FND_GLOBAL.conc_request_id,
                p_exception      => 'XX_CN_AR_EXTRACT.EXTRACT_CLAWBACKS',
                p_message        => lc_err_reason,
                p_code           => -1,
                p_err_code       => 'EXTRACT_CLAWBACKS_VAL_CHECK'
               );
               xx_cn_util_pkg.DEBUG (lc_err_reason);
         END IF;
      END LOOP;
      END IF;
      ----------------------------------------------------------------------------
      --Bulk Insert success records from LT_AR_SUCCESS_TBL_TYPE into XX_CN_AR_TRX
      ----------------------------------------------------------------------------
      IF(ln_success_idx > 0) THEN
      FORALL i IN lt_ar_success_tbl_type.FIRST .. lt_ar_success_tbl_type.LAST
          INSERT INTO xx_cn_ar_trx
               VALUES lt_ar_success_tbl_type(i);
      END IF; 
      ----------------------------------------------------------------------------
      --Report all errored records to the End User
      ----------------------------------------------------------------------------
      IF(ln_failure_idx > 0) THEN
      xx_cn_util_pkg.display_out        (' Records having NULL Revenue Class                 :              '||LPAD(ln_null_rev_class,15));
      xx_cn_util_pkg.display_out        ('');
      xx_cn_util_pkg.display_out        (' Records having NULL Division                      :              '||LPAD(ln_null_div,15));
      xx_cn_util_pkg.display_out        ('');
      xx_cn_util_pkg.display_out        (' Records having NULL Private Brand                 :              '||LPAD(ln_null_priv_band,15));
      xx_cn_util_pkg.display_out        ('');
      xx_cn_util_pkg.display_out        (' Records having NULL PO Cost                       :              '||LPAD(ln_null_po_cost,15));
      xx_cn_util_pkg.display_out        ('');
      xx_cn_util_pkg.display_out        (' Records having NULL Rollup Date                   :              '||LPAD(ln_null_rollup_date,15));
      xx_cn_util_pkg.display_out        ('');
      xx_cn_util_pkg.display_out        (' Records having NULL Transaction Amount            :              '||LPAD(ln_null_trx_amt,15));
      xx_cn_util_pkg.display_out        ('');
      xx_cn_util_pkg.display_out        (' Records having NULL Quantity                      :              '||LPAD(ln_null_qty,15));
      xx_cn_util_pkg.display_out        ('');
      xx_cn_util_pkg.display_out        (' Number of Errored Clawback Records                :              '||LPAD(ln_failure_idx,15));
      xx_cn_util_pkg.display_out        ('');
      xx_cn_util_pkg.display_out        (' (The Errored Records have a NULL or INVALID value in Revenue Class ID, Division, Private Brand, PO Cost, Department Code, Class Code, Transaction Amount, Quantity or Rollup Date.)');
      xx_cn_util_pkg.display_out        ('');
      xx_cn_util_pkg.display_out        (RPAD (' ', 330, '_'));
      xx_cn_util_pkg.display_out 
                                        (     RPAD (' CUSTOMER_ID', 15)
                                           || CHR(9)
                                           || RPAD ('INVENTORY_ITEM_ID', 20)
                                           || CHR(9)
                                           || RPAD ('INVOICE_NUMBER', 20)
                                           || CHR(9)
                                           || RPAD ('INVOICE_DATE', 15)
                                           || CHR(9)
                                           || RPAD ('INVOICE_LINE', 15)
                                           || CHR(9)
                                           || RPAD ('LINE_ID', 15)
                                           || CHR(9)
                                           || RPAD ('ROLLUP_DATE', 15)
                                           || CHR(9)
                                           || LPAD ('TRANSACTION_AMOUNT', 25)
                                           || RPAD (' ', 5)
                                           || CHR(9)
                                           || LPAD ('QUANTITY', 10)
                                           || RPAD (' ', 5)
                                           || CHR(9)
                                           || LPAD ('COST', 10)
                                           || RPAD (' ', 5)
                                           || CHR(9)
                                           || RPAD ('PRIVATE_BRAND', 15)
                                           || CHR(9)
                                           || RPAD ('DIVISION', 15)
                                           || CHR(9)
                                           || RPAD ('REVENUE_CLASS', 15)
                                           || CHR(9)
                                           || RPAD ('DEPT_CODE', 15)
                                           || CHR(9)
                                           || RPAD ('CLASS_CODE', 15)
                                           || CHR(9)
                                           || RPAD ('ERROR_MESSAGE', 240)
                                        );
      xx_cn_util_pkg.display_out        (RPAD (' ', 330, '_'));
      FOR i IN lt_ar_failure_tbl_type.FIRST .. lt_ar_failure_tbl_type.LAST
      LOOP
      xx_cn_util_pkg.display_out 
                                        (     RPAD (' '||NVL(TO_CHAR(lt_ar_failure_tbl_type(i).customer_id),' '), 15)
                                           || CHR(9)
                                           || RPAD (NVL(TO_CHAR(lt_ar_failure_tbl_type(i).inventory_item_id),' '), 20)
                                           || CHR(9)
                                           || RPAD (NVL(TO_CHAR(lt_ar_failure_tbl_type(i).invoice_number),' '), 20)
                                           || CHR(9)
                                           || RPAD (NVL(TO_CHAR(lt_ar_failure_tbl_type(i).invoice_date),' '), 15)
                                           || CHR(9)
                                           || RPAD (NVL(TO_CHAR(lt_ar_failure_tbl_type(i).line_number),' '), 15)
                                           || CHR(9)
                                           || RPAD (NVL(TO_CHAR(lt_ar_failure_tbl_type(i).source_trx_line_id),' '), 15)
                                           || CHR(9)
                                           || RPAD (NVL(TO_CHAR(lt_ar_failure_tbl_type(i).rollup_date),' '), 15)
                                           || CHR(9)
                                           || LPAD (NVL(TRIM(TO_CHAR(ROUND(lt_ar_failure_tbl_type(i).transaction_amount,2),'9,999,999,999,999,999,999,999,999,999,999,999,999.99')),' '), 25)
                                           || RPAD (' ', 5)
                                           || CHR(9)
                                           || LPAD (NVL(TO_CHAR(lt_ar_failure_tbl_type(i).quantity),' '), 10)
                                           || RPAD (' ', 5)
                                           || CHR(9)
                                           || LPAD (NVL(TRIM(TO_CHAR(ROUND(lt_ar_failure_tbl_type(i).cost,2),'9,999,999,999,999,999,999,999,999,999,999,999,999.99')),' '), 10)
                                           || RPAD (' ', 5)
                                           || CHR(9)
                                           || RPAD (NVL(TO_CHAR(lt_ar_failure_tbl_type(i).private_brand),' '), 15)
                                           || CHR(9)
                                           || RPAD (NVL(TO_CHAR(lt_ar_failure_tbl_type(i).division),' '), 15)
                                           || CHR(9)
                                           || RPAD (NVL(TO_CHAR(lt_ar_failure_tbl_type(i).revenue_class_id),' '), 15)
                                           || CHR(9)
                                           || RPAD (NVL(TO_CHAR(lt_ar_failure_tbl_type(i).department_code),' '), 15)
                                           || CHR(9)
                                           || RPAD (NVL(TO_CHAR(lt_ar_failure_tbl_type(i).class_code),' '), 15)
                                           || CHR(9)
                                           || RPAD (NVL(TO_CHAR(lt_error_tbl_type(i)),' '), 240)
                                        );
      END LOOP;
      xx_cn_util_pkg.display_out        (RPAD (' ', 330, '_'));
      xx_cn_util_pkg.display_out        ('');
      x_retcode                         := 1;
      x_errbuf                          := 'Procedure: EXTRACT_CLAWBACKS: This Batch has some errored Records';
      END IF;
           
      ln_trx_count := ln_trx_count + ln_success_idx;
      
      EXIT WHEN lcu_ar_cbk_data%NOTFOUND;
      END LOOP;
      CLOSE lcu_ar_cbk_data;
      
      fnd_message.set_name              ('XXCRM', 'XX_OIC_0016_CBK_ROWS_EXT');
      fnd_message.set_token             ('TRX_COUNT', ln_trx_count);
      fnd_message.set_token             ('BATCH_ID', p_batch_id);
      lc_message_data                   := fnd_message.get;
      xx_cn_util_pkg.WRITE              ('EXTRACT_CLAWBACKS: ' || lc_message_data,'LOG');
      xx_cn_util_pkg.display_log        ('EXTRACT_CLAWBACKS: ' || lc_message_data);
      xx_cn_util_pkg.display_out        (' Number of clawback lines extracted                :              '|| LPAD(ln_trx_count,15));
      xx_cn_util_pkg.display_out        ('');
      xx_cn_util_pkg.display_out        (LPAD ('*************End of Program************************',86));
      xx_cn_util_pkg.display_out        (RPAD (' ', 330, '_'));
      ----------------------------------------------------------------------
      --Updating the EXTRACTED_FLAG on XX_CN_NOT_TRX for successful records
      ----------------------------------------------------------------------
      UPDATE xx_cn_not_trx cnt
         SET extracted_flag = G_YES
       WHERE cnt.event_id = cn_global.cbk_event_id
         AND cnt.extracted_flag = G_NO
         AND cnt.batch_id = p_batch_id
         AND (source_trx_id,source_trx_line_id) IN
         (select payment_schedule_id,source_trx_line_id
           from XX_CN_AR_TRX 
          where event_id = cn_global.cbk_event_id
           AND batch_id = p_batch_id);

    ---------------------------------------------------------------------
    --Updating Margin details on XX_CN_AR_TRX
    ---------------------------------------------------------------------
      xx_cn_util_pkg.DEBUG              ('EXTRACT_CLAWBACKS: Setting Margin Amounts');
      xx_cn_util_pkg.display_log        ('EXTRACT_CLAWBACKS: Setting Margin Amounts');

      UPDATE xx_cn_ar_trx
         SET margin =
                DECODE (drop_ship_flag,
                        G_YES, transaction_amount - (quantity * COST),
                        G_NO, (transaction_amount * 1.1) - (quantity * COST)
                       )
       WHERE batch_id = p_batch_id;

      COMMIT;
      xx_cn_util_pkg.update_batch       (ln_proc_audit_id, 0, lc_message_data);
      xx_cn_util_pkg.WRITE              ('<<End EXTRACT_CLAWBACKS>>', 'LOG');
      xx_cn_util_pkg.display_log        ('<<End EXTRACT_CLAWBACKS>>');
      -------------------------------------------------
      --Process Audit End Batch for EXTRACT_CLAWBACKS
      -------------------------------------------------
      xx_cn_util_pkg.end_batch          (ln_proc_audit_id);
   EXCEPTION
      WHEN OTHERS
      THEN
         ROLLBACK;
         ln_message_code := -1;
         fnd_message.set_name           ('XXCRM', 'XX_OIC_0010_UNEXPECTED_ERR');
         fnd_message.set_token          ('SQL_CODE', SQLCODE);
         fnd_message.set_token          ('SQL_ERR', SQLERRM);
         lc_message_data                := fnd_message.get;
         xx_cn_util_pkg.log_error
                                        (p_prog_name      => 'XX_CN_AR_EXTRACT.EXTRACT_CLAWBACKS',
                                         p_prog_type      => G_PROG_TYPE,
                                         p_prog_id        => FND_GLOBAL.conc_request_id,
                                         p_exception      => 'XX_CN_AR_EXTRACT.EXTRACT_CLAWBACKS',
                                         p_message        => lc_message_data,
                                         p_code           => ln_message_code,
                                         p_err_code       => 'XX_OIC_0010_UNEXPECTED_ERR'
                                        );
         lc_errmsg                      := 'Procedure: EXTRACT_CLAWBACKS: ' || lc_message_data;
         xx_cn_util_pkg.DEBUG           ('--Error:' || lc_errmsg);
         xx_cn_util_pkg.display_log     ('--Error:' || lc_errmsg);
         xx_cn_util_pkg.update_batch    (ln_proc_audit_id,SQLCODE,lc_message_data);
         xx_cn_util_pkg.WRITE           ('<<End EXTRACT_CLAWBACKS>>', 'LOG');
         xx_cn_util_pkg.display_log     ('<<End EXTRACT_CLAWBACKS>>');
         xx_cn_util_pkg.end_batch       (ln_proc_audit_id);
         x_retcode                      := 2;
         x_errbuf                       := 'Procedure: EXTRACT_CLAWBACKS: ' || lc_message_data;
         RAISE;
   END extract_clawbacks;
-- +===========================================================================================================+
-- | Name        :  extract_givebacks
-- | Description :  This procedure is used to extract AR Giveback Data.
-- | Parameters  :  x_errbuf       OUT   VARCHAR2,
-- |                x_retcode      OUT   NUMBER,
-- |                p_batch_id           NUMBER,
-- |                p_process_audit_id   NUMBER
-- +===========================================================================================================+
   PROCEDURE extract_givebacks (
      x_errbuf             OUT   VARCHAR2,
      x_retcode            OUT   NUMBER,
      p_batch_id                 NUMBER,
      p_process_audit_id         NUMBER
   )
   IS
      ln_proc_audit_id       NUMBER;
      ln_rev_class           NUMBER;
      ln_message_code        NUMBER;
      ln_trx_count           NUMBER;
      ln_success_idx         NUMBER;
      ln_failure_idx         NUMBER;
      ln_null_rev_class      NUMBER;
      ln_null_div            NUMBER;
      ln_null_priv_band      NUMBER;
      ln_null_po_cost        NUMBER;
      ln_null_rollup_date    NUMBER;
      ln_null_trx_amt        NUMBER;
      ln_null_qty            NUMBER;
      
      L_LIMIT_SIZE           PLS_INTEGER    := 10000;
      
      lc_dept_code           xx_cn_ar_trx.department_code%TYPE;
      lc_class_code          xx_cn_ar_trx.class_code%TYPE;
      lc_orig_order_source   xx_cn_ar_trx.original_order_source%TYPE;
      lc_division            xx_cn_ar_trx.division%TYPE;
      lc_private_brand       xx_cn_ar_trx.private_brand%TYPE;
      
      lc_message_data        VARCHAR2 (4000);
      lc_errmsg              VARCHAR2 (4000);
      lc_desc                VARCHAR2 (240);
      lc_err_reason          VARCHAR2 (4000);
      
      lt_ar_tbl_type         xx_ar_tbl_type;
      lt_ar_success_tbl_type xx_ar_tbl_type;
      lt_ar_failure_tbl_type xx_ar_tbl_type;
      lt_error_tbl_type      xx_error_tbl_type;

      CURSOR lcu_ar_gbk_data
      IS
      SELECT xx_cn_ar_trx_s.NEXTVAL,GBK.*
        FROM
       (SELECT  
        NULL AS booked_date,
        NULL AS order_date, 
        NULL AS salesrep_id,
        rct.sold_to_customer_id AS customer_id,
        rctl.inventory_item_id, 
        rct.ct_reference AS order_number,
        rctl.line_number,
        (SELECT header_id
           FROM oe_order_headers_all
          WHERE order_number = rct.ct_reference
            AND org_id = rct.org_id) AS order_header_id,
        rctl.interface_line_attribute6 AS order_line_id,
        rct.trx_number AS invoice_number,
        rct.trx_date AS invoice_date, 
        cnt.processed_date,
        (SELECT cp.period_id
           FROM cn_acc_period_statuses_v cp
          WHERE cnt.processed_date
                   BETWEEN cp.start_date
                       AND cp.end_date) AS processed_period_id,
        rct.org_id AS org_id, 
        cn_global.gbk_event_id AS event_id,
        G_REVENUE_TYPE AS revenue_type,
        (SELECT cust_acct_site_id
           FROM hz_cust_site_uses_all
          WHERE site_use_id = rct.ship_to_site_use_id) AS ship_to_address_id,
        (SELECT a.party_site_id
           FROM hz_cust_acct_sites_all a,
                hz_cust_site_uses_all  b   
         WHERE  a.cust_acct_site_id = b.cust_acct_site_id
           AND  b.site_use_id       = rct.ship_to_site_use_id       -- Included derivation of party_site_id as per table design change
           AND  a.org_id            = rct.org_id) AS party_site_id, -- Changes made on 7-Nov-2007
        rct.ship_date_actual AS rollup_date, 
        G_SRC_DOC_TYPE,
        ara.applied_customer_trx_id, 
        rctl.customer_trx_line_id,
        rct.trx_number, 
        ara.applied_payment_schedule_id,
        ara.receivable_application_id,
        NVL (rctl.quantity_invoiced, 0) AS quantity,
        (rctl.extended_amount / aps.amount_line_items_original)* ara.line_applied AS amount,
        rct.invoice_currency_code, 
        G_GBK_TRX_TYPE AS trx_type,
        NULL AS class_code, 
        NULL AS dept_code,
        (SELECT od_private_brand_flg
           FROM xx_inv_item_master_attributes
          WHERE inventory_item_id = rctl.inventory_item_id),
        (SELECT po_cost
           FROM xx_om_line_attributes_all
          WHERE line_id = rctl.interface_line_attribute6),
        NULL AS division, 
        NULL AS revenue_class_id,
        (CASE (SELECT source_type_code
                FROM oe_order_lines_all
               WHERE line_id = rctl.interface_line_attribute6)
         WHEN G_ORD_SRC_TYPE THEN G_YES
         ELSE G_NO END ) AS drop_ship_flag, 
        NULL AS margin,
        NULL AS discount_percentage, 
        rct.exchange_rate,
        NULL AS return_reason_code,
        (SELECT NAME
           FROM oe_order_sources
          WHERE order_source_id =
                   (SELECT order_source_id
                      FROM oe_order_headers_all
                     WHERE order_number = rct.ct_reference
                       AND org_id = rct.org_id)) AS original_order_source,
        G_NO AS summarized_flag, 
        G_NO AS salesrep_assign_flag,
        cnt.batch_id,
        NULL as trnsfr_batch_id,
        NULL as summ_batch_id,
        p_process_audit_id, 
        fnd_global.conc_request_id,
        FND_GLOBAL.prog_appl_id AS program_application_id,
        TO_NUMBER (fnd_global.user_id) AS created_by,
        SYSDATE AS creation_date,
        TO_NUMBER (fnd_global.user_id) AS last_updated_by,
        SYSDATE AS last_update_date,
        TO_NUMBER (fnd_global.login_id) AS last_update_login
           FROM xx_cn_not_trx cnt,
                ar_receivable_applications ara,
                ra_customer_trx rct,
                ra_customer_trx_lines rctl,
                ra_batch_sources rbs,
                ar_payment_schedules aps
          WHERE cnt.source_trx_id = ara.receivable_application_id
            AND rct.customer_trx_id = ara.applied_customer_trx_id
            AND cnt.source_trx_line_id = rctl.customer_trx_line_id
            AND rct.org_id = fnd_global.org_id
            AND EXISTS (
                   SELECT ar_trx_id
                     FROM xx_cn_ar_trx cat
                    WHERE cat.payment_schedule_id = ara.applied_payment_schedule_id
                      AND source_trx_line_id = rctl.customer_trx_line_id
                      AND cat.trx_type = G_CBK_TRX_TYPE
                      AND rownum > 0 )
            AND cnt.event_id = cn_global.gbk_event_id
            AND cnt.extracted_flag = G_NO
            AND ara.applied_customer_trx_id = rctl.customer_trx_id
            AND rctl.line_type = G_CUST_TRX_LINE_TYPE
            AND rct.batch_source_id = rbs.batch_source_id
            AND rbs.NAME IN (
                   SELECT meaning
                     FROM fnd_lookups
                    WHERE lookup_type = G_ORDER_SOURCE
                      AND enabled_flag = G_YES)
            AND EXISTS (
                   SELECT cust_account_id
                     FROM hz_cust_accounts hca
                    WHERE hca.cust_account_id = rct.sold_to_customer_id
                      AND hca.attribute18 = G_CUST_TYPE
                      AND rownum > 0 )
            AND aps.payment_schedule_id = ara.applied_payment_schedule_id
            AND cnt.batch_id = p_batch_id
            AND rownum > 0 
          ORDER BY rct.sold_to_customer_id,
                   rct.trx_number,
                   rctl.line_number) GBK;
   BEGIN
      lc_desc                           := 'Extract Givebacks for Batch:'|| p_batch_id;
      -------------------------------------------------
      --Process Audit Begin Batch for EXTRACT_GIVEBACKS
      -------------------------------------------------
      xx_cn_util_pkg.begin_batch
                                        (p_parent_proc_audit_id      => p_process_audit_id,
                                         x_process_audit_id          => ln_proc_audit_id,
                                         p_request_id                => fnd_global.conc_request_id,
                                         p_process_type              => G_EXTRACT_GB,
                                         p_description               => lc_desc
                                        );
      xx_cn_util_pkg.display_out        (RPAD (' Office Depot', 100)|| 'Date:'|| SYSDATE);
      xx_cn_util_pkg.display_out        (LPAD('OD AR Extract Givebacks Child program',70)|| LPAD ('Page:1', 36));
      xx_cn_util_pkg.display_out        (RPAD (' ', 330, '_'));

      xx_cn_util_pkg.display_out        ('');
      xx_cn_util_pkg.display_out        ('');
      xx_cn_util_pkg.display_out        ('');

      xx_cn_util_pkg.WRITE              ('<<Begin EXTRACT_GIVEBACKS>>', 'LOG');
      xx_cn_util_pkg.display_log        ('<<Begin EXTRACT_GIVEBACKS>>');
      xx_cn_util_pkg.DEBUG              ('EXTRACT_GIVEBACKS: Batch Size:'|| gn_xfer_batch_size);
      xx_cn_util_pkg.display_log        ('EXTRACT_GIVEBACKS: Batch Size:'|| gn_xfer_batch_size);
      
      select organization_id into gn_master_org_id
       from mtl_parameters
      where organization_id = master_organization_id;
      
      xx_cn_util_pkg.DEBUG              ('EXTRACT_GIVEBACKS: Before inserting data into XX_CN_AR_TRX');
      xx_cn_util_pkg.display_log        ('EXTRACT_GIVEBACKS: Before inserting data into XX_CN_AR_TRX');
      xx_cn_util_pkg.display_out        (' Batch ID                                          :              '||LPAD(p_batch_id,15));
      xx_cn_util_pkg.display_out        ('');

      ----------------------------------------------
      --Begin loop for BULK Insert
      -----------------------------------------------
      ln_trx_count := 0;
      OPEN lcu_ar_gbk_data;
      LOOP
         -------------------------------------------------
         --Initializing table types and their indexes
         -------------------------------------------------
         lt_ar_tbl_type.DELETE;
         lt_ar_success_tbl_type.DELETE;
         ln_success_idx := 0;
         lt_ar_failure_tbl_type.DELETE;
         ln_failure_idx := 0;
         lt_error_tbl_type.DELETE;
         ln_null_rev_class  := 0;     
         ln_null_div        := 0;         
         ln_null_priv_band  := 0;     
         ln_null_po_cost    := 0;      
         ln_null_rollup_date:= 0;  
         ln_null_trx_amt    := 0;     
         ln_null_qty        := 0; 
         
         FETCH lcu_ar_gbk_data
         BULK COLLECT INTO lt_ar_tbl_type LIMIT L_LIMIT_SIZE;

      --------------------------------------------------------------------
      --Obtaining Dept, Class, Division and Revenue class for each record
      --------------------------------------------------------------------
      IF(lt_ar_tbl_type.COUNT > 0) THEN
      FOR idx IN lt_ar_tbl_type.FIRST .. lt_ar_tbl_type.LAST
      LOOP
         IF(lt_ar_tbl_type (idx).private_brand IS NOT NULL) THEN
         OPEN gcu_mtl_item_details (lt_ar_tbl_type (idx).inventory_item_id,gn_master_org_id);

         FETCH gcu_mtl_item_details
          INTO lt_ar_tbl_type (idx).department_code,
               lt_ar_tbl_type (idx).class_code;
         CLOSE gcu_mtl_item_details;

         xx_cn_util_pkg.xx_cn_get_division
                                        (p_dept_code           => lt_ar_tbl_type (idx).department_code,
                                         p_class_code          => lt_ar_tbl_type (idx).class_code,
                                         p_order_source        => lt_ar_tbl_type (idx).original_order_source,
                                         p_collect_source      => NULL,
                                         p_private_brand       => lt_ar_tbl_type (idx).private_brand,
                                         x_division            => lt_ar_tbl_type (idx).division,
                                         x_rev_class_id        => lt_ar_tbl_type (idx).revenue_class_id
                                        );
        
         END IF;

         IF(lt_ar_tbl_type (idx).revenue_class_id is NOT NULL 
            AND lt_ar_tbl_type (idx).division IS NOT NULL
            AND lt_ar_tbl_type (idx).private_brand IS NOT NULL
            AND lt_ar_tbl_type (idx).cost IS NOT NULL
            AND lt_ar_tbl_type (idx).rollup_date IS NOT NULL
            AND lt_ar_tbl_type (idx).transaction_amount IS NOT NULL
            AND lt_ar_tbl_type (idx).quantity IS NOT NULL)
           THEN
               --------------------------------------------------------------------
               --Inserting success records into LT_AR_SUCCESS_TBL_TYPE
               --------------------------------------------------------------------
               lt_ar_success_tbl_type(ln_success_idx) := lt_ar_tbl_type (idx);
               ln_success_idx := ln_success_idx +1;
         ELSE
               --------------------------------------------------------------------
               --Inserting failure records into LT_AR_FAILURE_TBL_TYPE for reporting
               --------------------------------------------------------------------
               lt_ar_failure_tbl_type(ln_failure_idx) := lt_ar_tbl_type (idx);
               lc_err_reason := ''; 
               IF(lt_ar_tbl_type (idx).revenue_class_id is NULL) THEN
                    lc_err_reason := 'Null REVENUE CLASS.'; 
                    ln_null_rev_class := ln_null_rev_class + 1;
               END IF;
               IF(lt_ar_tbl_type (idx).division IS NULL) THEN
                    lc_err_reason := lc_err_reason||'Null DIVISION.'; 
                    ln_null_div := ln_null_div + 1;
               END IF;
               IF(lt_ar_tbl_type (idx).private_brand IS NULL) THEN
                    lc_err_reason := lc_err_reason||'Null PRIVATE BRAND.';
                    ln_null_priv_band := ln_null_priv_band + 1;
               END IF;
               IF(lt_ar_tbl_type (idx).cost IS NULL) THEN
                    lc_err_reason := lc_err_reason||'Null PO COST.';
                    ln_null_po_cost := ln_null_po_cost + 1;
               END IF;
               IF(lt_ar_tbl_type (idx).rollup_date IS NULL) THEN
                    lc_err_reason := lc_err_reason||'Null ROLLUP DATE.';
                    ln_null_rollup_date := ln_null_rollup_date + 1;
               END IF;
               IF(lt_ar_tbl_type (idx).transaction_amount IS NULL) THEN
                    lc_err_reason := lc_err_reason||'Null TRANSACTION AMOUNT.';
                    ln_null_trx_amt := ln_null_trx_amt + 1;
               END IF;
               IF(lt_ar_tbl_type (idx).quantity IS NULL) THEN
                    lc_err_reason := lc_err_reason||'Null QUANTITY.';
                    ln_null_qty := ln_null_qty + 1;
               END IF;
               lt_error_tbl_type(ln_failure_idx) := lc_err_reason;
               ln_failure_idx := ln_failure_idx +1;
               
               lc_err_reason := 'Invoice Number:'||lt_ar_tbl_type (idx).invoice_number||
                                ' Invoice Line:'||lt_ar_tbl_type (idx).line_number|| 
                                ' Line ID:'||lt_ar_tbl_type (idx).source_trx_line_id|| 
                                ' '||lc_err_reason;               
               xx_cn_util_pkg.log_error
               (p_prog_name      => 'XX_CN_AR_EXTRACT.EXTRACT_GIVEBACKS',
                p_prog_type      => G_PROG_TYPE,
                p_prog_id        => FND_GLOBAL.conc_request_id,
                p_exception      => 'XX_CN_AR_EXTRACT.EXTRACT_GIVEBACKS',
                p_message        => lc_err_reason,
                p_code           => -1,
                p_err_code       => 'EXTRACT_GIVEBACKS_VAL_CHECK'
               );
               xx_cn_util_pkg.DEBUG (lc_err_reason);
         END IF;
      END LOOP;
      END IF;
      ----------------------------------------------------------------------------
      --Bulk Insert success records from LT_AR_SUCCESS_TBL_TYPE into XX_CN_AR_TRX
      ----------------------------------------------------------------------------
      IF(ln_success_idx > 0) THEN
      FORALL i IN lt_ar_success_tbl_type.FIRST .. lt_ar_success_tbl_type.LAST
          INSERT INTO xx_cn_ar_trx
               VALUES lt_ar_success_tbl_type(i);
      END IF;
               
      ----------------------------------------------------------------------------
      --Report all errored records to the End User
      ----------------------------------------------------------------------------
      IF(ln_failure_idx > 0) THEN
      xx_cn_util_pkg.display_out        (' Records having NULL Revenue Class                 :              '||LPAD(ln_null_rev_class,15));
      xx_cn_util_pkg.display_out        ('');
      xx_cn_util_pkg.display_out        (' Records having NULL Division                      :              '||LPAD(ln_null_div,15));
      xx_cn_util_pkg.display_out        ('');
      xx_cn_util_pkg.display_out        (' Records having NULL Private Brand                 :              '||LPAD(ln_null_priv_band,15));
      xx_cn_util_pkg.display_out        ('');
      xx_cn_util_pkg.display_out        (' Records having NULL PO Cost                       :              '||LPAD(ln_null_po_cost,15));
      xx_cn_util_pkg.display_out        ('');
      xx_cn_util_pkg.display_out        (' Records having NULL Rollup Date                   :              '||LPAD(ln_null_rollup_date,15));
      xx_cn_util_pkg.display_out        ('');
      xx_cn_util_pkg.display_out        (' Records having NULL Transaction Amount            :              '||LPAD(ln_null_trx_amt,15));
      xx_cn_util_pkg.display_out        ('');
      xx_cn_util_pkg.display_out        (' Records having NULL Quantity                      :              '||LPAD(ln_null_qty,15));
      xx_cn_util_pkg.display_out        ('');
      xx_cn_util_pkg.display_out        (' Number of Errored Giveback Records                :              '||LPAD(ln_failure_idx,15));
      xx_cn_util_pkg.display_out        ('');
      xx_cn_util_pkg.display_out        (' (The Errored Records have a NULL or INVALID value in Revenue Class ID, Division, Department Code, Class Code, Transaction Amount, Quantity or Rollup Date.)');
      xx_cn_util_pkg.display_out        ('');
      xx_cn_util_pkg.display_out        (RPAD (' ', 330, '_'));
      xx_cn_util_pkg.display_out 
                                        (    RPAD (' CUSTOMER_ID', 15)
                                          || CHR(9)
                                          || RPAD ('INVENTORY_ITEM_ID', 20)
                                          || CHR(9)
                                          || RPAD ('INVOICE_NUMBER', 20)
                                          || CHR(9)
                                          || RPAD ('INVOICE_DATE', 15)
                                          || CHR(9)
                                          || RPAD ('INVOICE_LINE', 15)
                                          || CHR(9)
                                          || RPAD ('LINE_ID', 15)
                                          || CHR(9)
                                          || RPAD ('ROLLUP_DATE', 15)
                                          || CHR(9)
                                          || LPAD ('TRANSACTION_AMOUNT', 25)   
                                          || RPAD (' ', 5)
                                          || CHR(9)
                                          || LPAD ('QUANTITY', 10)
                                          || RPAD (' ', 5)
                                          || CHR(9)
                                          || LPAD ('COST', 10)
                                          || RPAD (' ', 5)
                                          || CHR(9)
                                          || RPAD ('PRIVATE_BRAND', 15)
                                          || CHR(9)
                                          || RPAD ('DIVISION', 15)
                                          || CHR(9)
                                          || RPAD ('REVENUE_CLASS', 15)
                                          || CHR(9)
                                          || RPAD ('DEPT_CODE', 15)
                                          || CHR(9)
                                          || RPAD ('CLASS_CODE', 15)
                                          || CHR(9)
                                          || RPAD ('ERROR_MESSAGE', 240)
                                        );
      xx_cn_util_pkg.display_out     (RPAD (' ', 330, '_'));
      FOR i IN lt_ar_failure_tbl_type.FIRST .. lt_ar_failure_tbl_type.LAST
      LOOP
      xx_cn_util_pkg.display_out 
                                        (     RPAD (' '||NVL(TO_CHAR(lt_ar_failure_tbl_type(i).customer_id),' '), 15)
                                           || CHR(9)
                                           || RPAD (NVL(TO_CHAR(lt_ar_failure_tbl_type(i).inventory_item_id),' '), 20)
                                           || CHR(9)
                                           || RPAD (NVL(TO_CHAR(lt_ar_failure_tbl_type(i).invoice_number),' '), 20)
                                           || CHR(9)
                                           || RPAD (NVL(TO_CHAR(lt_ar_failure_tbl_type(i).invoice_date),' '), 15)
                                           || CHR(9)
                                           || RPAD (NVL(TO_CHAR(lt_ar_failure_tbl_type(i).line_number),' '), 15)
                                           || CHR(9)
                                           || RPAD (NVL(TO_CHAR(lt_ar_failure_tbl_type(i).source_trx_line_id),' '), 15)
                                           || CHR(9)
                                           || RPAD (NVL(TO_CHAR(lt_ar_failure_tbl_type(i).rollup_date),' '), 15)
                                           || CHR(9)
                                           || LPAD (NVL(TRIM(TO_CHAR(ROUND(lt_ar_failure_tbl_type(i).transaction_amount,2),'9,999,999,999,999,999,999,999,999,999,999,999,999.99')),' '), 25)
                                           || RPAD (' ', 5)
                                           || CHR(9)
                                           || LPAD (NVL(TO_CHAR(lt_ar_failure_tbl_type(i).quantity),' '), 10)
                                           || RPAD (' ', 5)
                                           || CHR(9)
                                           || LPAD (NVL(TO_CHAR(ROUND(lt_ar_failure_tbl_type(i).cost,2),'9,999,999,999,999,999,999,999,999,999,999,999,999.99'),' '), 10)
                                           || RPAD (' ', 5)
                                           || CHR(9)
                                           || RPAD (NVL(TO_CHAR(lt_ar_failure_tbl_type(i).private_brand),' '), 15)
                                           || CHR(9)
                                           || RPAD (NVL(TO_CHAR(lt_ar_failure_tbl_type(i).division),' '), 15)
                                           || CHR(9)
                                           || RPAD (NVL(TO_CHAR(lt_ar_failure_tbl_type(i).revenue_class_id),' '), 15)
                                           || CHR(9)
                                           || RPAD (NVL(TO_CHAR(lt_ar_failure_tbl_type(i).department_code),' '), 15)
                                           || CHR(9)
                                           || RPAD (NVL(TO_CHAR(lt_ar_failure_tbl_type(i).class_code),' '), 15)
                                           || CHR(9)
                                           || RPAD (NVL(TO_CHAR(lt_error_tbl_type(i)),' '), 240)
                                        );
      END LOOP;
      xx_cn_util_pkg.display_out        (RPAD (' ', 330, '_'));
      xx_cn_util_pkg.display_out        ('');
      x_retcode                         := 1;
      x_errbuf                          := 'Procedure: EXTRACT_GIVEBACKS: This Batch has some errored Records';
      END IF;
               
      ln_trx_count                      := ln_trx_count + ln_success_idx;
               
      EXIT WHEN lcu_ar_gbk_data%NOTFOUND;
      END LOOP;
      CLOSE lcu_ar_gbk_data;
      
      fnd_message.set_name              ('XXCRM', 'XX_OIC_0017_GBK_ROWS_EXT');
      fnd_message.set_token             ('TRX_COUNT', ln_trx_count);
      fnd_message.set_token             ('BATCH_ID', p_batch_id);
      lc_message_data                   := fnd_message.get;
      xx_cn_util_pkg.WRITE              ('EXTRACT_GIVEBACKS: ' || lc_message_data,'LOG');
      xx_cn_util_pkg.display_log        ('EXTRACT_GIVEBACKS: ' || lc_message_data);
      xx_cn_util_pkg.display_out        (' Number of giveback lines extracted                :              '|| LPAD(ln_trx_count,15));
      xx_cn_util_pkg.display_out        ('');
      xx_cn_util_pkg.display_out        (LPAD ('*************End of Program************************',86));
      xx_cn_util_pkg.display_out        (RPAD (' ', 330, '_'));

      ----------------------------------------------------------------------
      --Updating the EXTRACTED_FLAG on XX_CN_NOT_TRX for successful records
      ----------------------------------------------------------------------
      UPDATE xx_cn_not_trx cnt
         SET extracted_flag = G_YES
       WHERE cnt.event_id = cn_global.gbk_event_id
         AND cnt.extracted_flag = G_NO
         AND cnt.batch_id = p_batch_id
         AND (source_trx_id,source_trx_line_id) IN
         (select receivable_application_id,source_trx_line_id
           from XX_CN_AR_TRX 
          where event_id = cn_global.gbk_event_id
           AND batch_id = p_batch_id);

      xx_cn_util_pkg.DEBUG              ('EXTRACT_GIVEBACKS: Setting Margin Amounts');
      xx_cn_util_pkg.display_log        ('EXTRACT_GIVEBACKS: Setting Margin Amounts');
    ---------------------------------------------------------------------
    --Updating Margin details on XX_CN_AR_TRX
    ---------------------------------------------------------------------
      UPDATE xx_cn_ar_trx
         SET margin =
                DECODE (drop_ship_flag,
                        G_NO, transaction_amount - (quantity * COST),
                        G_YES, (transaction_amount * 1.1) - (quantity * COST)
                       )
       WHERE batch_id = p_batch_id;

      COMMIT;
      xx_cn_util_pkg.update_batch       (ln_proc_audit_id, 0, lc_message_data);
      xx_cn_util_pkg.WRITE              ('<<End EXTRACT_GIVEBACKS>>', 'LOG');
      xx_cn_util_pkg.display_log        ('<<End EXTRACT_GIVEBACKS>>');
      ---------------------------------------------------------------------
      --Process Audit End Batch for EXTRACT_GIVEBACKS
      ---------------------------------------------------------------------
      xx_cn_util_pkg.end_batch       (ln_proc_audit_id);
   EXCEPTION
      WHEN OTHERS
      THEN
         ROLLBACK;
         ln_message_code := -1;
         fnd_message.set_name           ('XXCRM', 'XX_OIC_0010_UNEXPECTED_ERR');
         fnd_message.set_token          ('SQL_CODE', SQLCODE);
         fnd_message.set_token          ('SQL_ERR', SQLERRM);
         lc_message_data                := fnd_message.get;
         xx_cn_util_pkg.log_error
                                        (p_prog_name      => 'XX_CN_AR_EXTRACT.EXTRACT_GIVEBACKS',
                                         p_prog_type      => G_PROG_TYPE,
                                         p_prog_id        => FND_GLOBAL.conc_request_id,
                                         p_exception      => 'XX_CN_AR_EXTRACT.EXTRACT_GIVEBACKS',
                                         p_message        => lc_message_data,
                                         p_code           => ln_message_code,
                                         p_err_code       => 'XX_OIC_0010_UNEXPECTED_ERR'
                                        );
         lc_errmsg                      := 'Procedure: EXTRACT_GIVEBACKS: ' || lc_message_data;
         xx_cn_util_pkg.DEBUG           ('--Error:' || lc_errmsg);
         xx_cn_util_pkg.display_log     ('--Error:' || lc_errmsg);
         xx_cn_util_pkg.update_batch    (ln_proc_audit_id,SQLCODE,lc_message_data);
         xx_cn_util_pkg.WRITE           ('<<End EXTRACT_GIVEBACKS>>', 'LOG');
         xx_cn_util_pkg.display_log     ('<<End EXTRACT_GIVEBACKS>>');
         xx_cn_util_pkg.end_batch       (ln_proc_audit_id);
         x_retcode                      := 2;
         x_errbuf                       := 'Procedure: EXTRACT_GIVEBACKS: ' || lc_message_data;
         RAISE;
   END extract_givebacks;
END XX_CN_AR_EXTRACT_PKG;
/

SHOW ERRORS
EXIT;
