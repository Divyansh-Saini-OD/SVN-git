CREATE OR REPLACE PACKAGE BODY xx_om_releasehold
AS
-- +=========================================================================+
-- |                  Office Depot - Project Simplify                        |
-- |                  Office Depot                                           |
-- +=========================================================================+
-- | Name  : XX_OM_RELEASEHOLD (XX_OM_RELEASEHOLD.PKS)                       |
-- | Description      : This Program is designed to release HOLDS,           |
-- |                    OD: SAS Pending deposit hold and                     |
-- |                    OD: Payment Processing Failure as an activity after  |
-- |                    Post production                                      |
-- |                                                                         |
-- |Change Record:                                                           |
-- |===============                                                          |
-- |Version Date        Author            Remarks        Description         |
-- |======= =========== =============     ===========   ===============      |
-- |DRAFT1A 20-JUL-12   Sanjit B        Initial draft version                |
-- |                                                                         |
-- | 1.0  04-OCT-12   Gayathri K          Defect # 20464   IF SO Type is POS |
-- |                                                                         |
-- |                                           and data is there in the ORDT |
-- |                                   then setting the p_return_status to S |
-- |                                                                         |
-- | 1.1    03-DEC-12   Gayathri K        Defect # 20937    Creating the     |
-- |                                                       Missing Receipts  |
-- | 1.2    14-NOV-13  Gayathri K         Defect # 23068  Creating Receipt   |
-- |                                                      for the Order,which|
-- |                                          is in the Hold Released Status,|
-- |      Updated tables Ra_customer_trx and lines to close missing Receipts|
-- |      and included Entered Status in the XX_OM_PPF_HOLD_RELEASE Procedure
-- | 1.3    26-NOV-13  Kiran Maddala         Defect # 23068  Included the    |
-- |                                     Code to release PPF Hold for Orders |
-- |                                     in ENTERED Status and Process them. |
-- | 1.4    10-JUN-14  Saritha M          Defect #27876 Fixing the available  |
-- |                                     balance issue in custom deposits    |
-- |                                     table                               |
-- | 1.5    09-11-2015   Shubashree R     R12.2  Compliance changes Defect#36354|
-- | 1.6    27-APR-2016  Surendra Oruganti Modified as per the defect 37647  |
-- | 1.7    04-APR-2017  Leelakrishna.G    Modified as per the defect 39944  |
-- +=========================================================================+

   -- Master Concurrent Program
   PROCEDURE xx_main_procedure (
      x_retcode             OUT NOCOPY      NUMBER,
      x_errbuf              OUT NOCOPY      VARCHAR2,
      p_order_number_from   IN              NUMBER,
      p_order_number_to     IN              NUMBER,
      p_date_from           IN              VARCHAR2,
      p_date_to             IN              VARCHAR2,
      p_sas_hold_param      IN              VARCHAR2,
      p_ppf_hold_param      IN              VARCHAR2,
      p_debug_flag          IN              VARCHAR2
   )
   AS
-- +=====================================================================+
-- | Name  : XX_MAIN_PROCEDURE                                           |
-- | Description     : The Main procedure to determine which Hold is to  |
-- |                   be released,OD: SAS Pending deposit hold or       |
-- |                   OD: Payment Processing Failure or both            |
-- | Parameters      : p_order_number_from IN ->Order Number             |
-- |                   P_ORDER_NUMBER_TO   IN ->Order Number             |
-- |                   P_date_FROM         IN ->Date Range(From)         |
-- |                   p_date_to           IN ->Date Range(To)           |
-- |                   p_SAS_HOLD_param    IN ->Flag of Y/N              |
-- |                   p_PPF_HOLD_param    IN ->Flag of Y/N              |
-- |                   x_retcode           OUT                           |
-- |                   x_errbuf            OUT                           |
-- |                   p_debug_flag        IN ->Debug flag               |
-- |                                           By default it will be N.  |
-- +=====================================================================+
      g_resp_id        NUMBER;
      g_resp_appl_id   NUMBER;
   BEGIN
      IF p_debug_flag = 'Y'
      THEN
         put_log_line (p_debug_flag, 'N', 'Start of prgram::: ');
         put_log_line (p_debug_flag,
                       'N',
                       'Calling XX_MAIN_PROCEDURE -- main procedure '
                      );
      END IF;

      put_log_line (p_debug_flag,
                    'N',
                    ' Before Calling the Procedure XX_CREATE_MISSING_RECEIPT '
                   );
      xx_create_missing_receipt (p_debug_flag);
      -- Added as part of the Defect # 20937
      put_log_line (p_debug_flag,
                    'N',
                    'After Calling the Procedure XX_CREATE_MISSING_RECEIPT '
                   );

      IF (p_sas_hold_param = 'Y')
      THEN
         IF p_debug_flag = 'Y'
         THEN
            put_log_line (p_debug_flag,
                          'N',
                          'Calling xx_om_sas_depo_release procedure '
                         );
         END IF;

         xx_om_sas_depo_release (p_order_number_from,
                                 p_order_number_to,
                                 p_date_from,
                                 p_date_to,
                                 p_debug_flag
                                );
      ELSE
         NULL;
      END IF;

      IF (p_ppf_hold_param = 'Y')
      THEN
         IF p_debug_flag = 'Y'
         THEN
            put_log_line (p_debug_flag,
                          'N',
                          'Calling xx_om_ppf_hold_release procedure '
                         );
         END IF;

         xx_om_ppf_hold_release (p_order_number_from,
                                 p_order_number_to,
                                 p_date_from,
                                 p_date_to,
                                 p_debug_flag
                                );
      ELSE
         NULL;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         fnd_file.put_line (fnd_file.LOG,
                               ' Exception raised at XX_MAIN_PROCEDURE ::: '
                            || SQLERRM
                           );
   END xx_main_procedure;

-- +============================================================================+
-- | Name             :  PUT_LOG_LINE                                           |
-- | Description      :  This procedure will print log messages.                |
-- | Parameters       :  p_debug  IN   -> Debug Flag - Default N.               |
-- |                  :  p_force  IN  -> Default Log - Default N                |
-- |                  :  p_buffer IN  -> Log Message.                           |
-- +============================================================================+
   PROCEDURE put_log_line (
      p_debug_flag   IN   VARCHAR2 DEFAULT 'N',
      p_force        IN   VARCHAR2 DEFAULT 'N',
      p_buffer       IN   VARCHAR2 DEFAULT ' '
   )
   AS
   BEGIN
      IF (p_debug_flag = 'Y' OR p_force = 'Y')
      THEN
         -- IF called from a concurrent program THEN print into log file
         IF (fnd_global.conc_request_id > 0)
         THEN
            fnd_file.put_line (fnd_file.LOG, NVL (p_buffer, ' '));
         -- ELSE print on console
         ELSE
            DBMS_OUTPUT.put_line (SUBSTR (NVL (p_buffer, ' '), 1, 300));
         END IF;
      END IF;
   END put_log_line;

-- +============================================================================+
-- | Name             :  XX_CREATE_MISSING_RECEIPT                              |
-- |                                                                            |
-- | Description      :  This procedure will create Prepayment Missing Receipts |
-- |                                                                            |
-- | Parameters       :  p_debug_flag       IN ->     By default it will be Y.  |
-- |                                                                            |
-- |Change Record:                                                              |
-- |===============                                                             |
-- |Version Date        Author            Remarks             Descripition      |
-- |======= =========== =============     ================  ==============      |
-- | 1.0    03-DEC-12   Gayathri K        Defect # 20937    Creating the        |
-- |                                                          Missing Receipts  |
-- |                                                                            |
-- | 1.2    09-MAR-13  Gayathri K         Defect # 23068  Creating Receipt      |
-- |                                                      for the Order,which   |
-- |                                             is in the Hold Released Status |
-- +============================================================================+
   PROCEDURE xx_create_missing_receipt (p_debug_flag IN VARCHAR2 DEFAULT 'Y')
   AS
      CURSOR lcu_aops_payments
      IS
         SELECT h.header_id, h.order_number, h.transactional_curr_code
           FROM oe_order_headers_all h,
                oe_payments i,
                xx_ar_order_receipt_dtl ordt
          WHERE ordt.cash_receipt_id = -3
--This condition will check that receipts are not created against sales orders
            AND ordt.header_id = h.header_id
            AND i.header_id = ordt.header_id
            AND ordt.order_source <> 'POE'
            -- Will not include POS Orders with Source as POE
            AND TRUNC (ordt.receipt_date) >= '01-OCT-12'
-- As per the Business requirement after this Date only this program needs to check for Missing Receipt Orders.
            AND i.header_id = h.header_id
            AND h.org_id = g_org_id
            AND i.attribute15 IS NULL
--This condition will make sure we are creating receipts only for the problematic sales orders
            AND NOT EXISTS (SELECT 1
                              FROM oe_order_holds_all oh
                             WHERE oh.header_id = ordt.header_id)
         --Added as part of the QC#20937
         UNION                          /*-- Added UNION as part of QC#23068*/
         SELECT h.header_id, h.order_number, h.transactional_curr_code
           FROM oe_order_headers_all h,
                oe_payments i,
                xx_ar_order_receipt_dtl ordt
          WHERE ordt.cash_receipt_id = -3
            AND ordt.header_id = h.header_id
            AND i.header_id = ordt.header_id
            AND ordt.order_source <> 'POE'
            AND TRUNC (ordt.receipt_date) >= '01-OCT-12'
            AND i.header_id = h.header_id
            AND h.org_id = g_org_id
            AND i.attribute15 IS NULL
            AND EXISTS (
                   SELECT 1
                     FROM oe_order_holds_all oh,
                          ar_payment_schedules_all aps
                    WHERE oh.header_id = ordt.header_id
                      AND oh.hold_release_id IS NOT NULL
                      AND aps.trx_number = TO_CHAR (h.order_number)
                      AND aps.status = 'OP');     -- Added as part of QC#23068

      TYPE t_aopspay_tab IS TABLE OF lcu_aops_payments%ROWTYPE
         INDEX BY PLS_INTEGER;

      l_aopspay_tab            t_aopspay_tab;
      l_p_debug_flag           VARCHAR2 (1);
      l_xx_pre_return_status   VARCHAR2 (1)                              := '';
      ln_cash_rec_id           xx_ar_order_receipt_dtl.cash_receipt_id%TYPE;
      l_tot_rec                NUMBER                                     := 0;
      l_receipt_number         ar_cash_receipts_all.receipt_number%TYPE;
      ---
      ln_payment_set_id        xx_ar_order_receipt_dtl.payment_set_id%TYPE
                                                                       := NULL;
      ln_request_id            ra_customer_trx_all.request_id%TYPE;
      ln_prepay_reqid          ra_customer_trx_all.request_id%TYPE;
   BEGIN
      put_log_line (p_debug_flag,
                    'N',
                    'Starting of the XX_CREATE_MISSING_RECEIPT Procedure:  '
                   );

      OPEN lcu_aops_payments;

      FETCH lcu_aops_payments
      BULK COLLECT INTO l_aopspay_tab;

      CLOSE lcu_aops_payments;

      put_log_line (p_debug_flag,
                    'Y',
                       'Total Number of Missing Receipt Orders are ::: '
                    || l_aopspay_tab.COUNT
                   );

      IF (l_aopspay_tab.COUNT > 0)
      THEN
         FOR i IN l_aopspay_tab.FIRST .. l_aopspay_tab.LAST
         LOOP
            --Debug Messages before calling the procedure
            IF p_debug_flag = 'Y'
            THEN
               put_log_line (p_debug_flag, 'N', ' ');
               put_log_line (p_debug_flag,
                             'N',
                                'Passing the HEADER_ID      : '
                             || l_aopspay_tab (i).header_id
                            );
               put_log_line
                  (p_debug_flag,
                   'N',
                      'Calling XX_CREATE_PREPAY_RECEIPT package for the Order :  '
                   || l_aopspay_tab (i).order_number
                  );
               put_log_line (p_debug_flag, 'N', ' ');
            END IF;

            --Calling Create Receipt Procedure
            l_p_debug_flag := p_debug_flag;
            xx_ar_prepay_receipt_pkg.xx_ar_prepay_receipt_proc
                                   (p_header_id          => l_aopspay_tab (i).header_id,
                                    p_return_status      => l_xx_pre_return_status
                                   );
            put_log_line (p_debug_flag, 'N', ' ');
            put_log_line (p_debug_flag,
                          'N',
                          'Return from XX_CREATE_PREPAY_RECEIPT ' || CHR (10)
                         );
            put_log_line (p_debug_flag, 'N', ' ');

            BEGIN
               SELECT arcash.cash_receipt_id, arcash.receipt_number
                 INTO ln_cash_rec_id, l_receipt_number
                 FROM xx_ar_order_receipt_dtl ordt,
                      ar_cash_receipts_all arcash
                WHERE ordt.cash_receipt_id = arcash.cash_receipt_id
                  AND ordt.header_id = l_aopspay_tab (i).header_id
                  AND ordt.cash_receipt_id <> -3;

               put_log_line (p_debug_flag,
                             'N',
                                'Cash Receipt ID = '
                             || ln_cash_rec_id
                             || '     Missing Receipt Number =  '
                             || l_receipt_number
                            );
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  ln_cash_rec_id := -3;
                  put_log_line
                     (p_debug_flag,
                      'N',
                         ' Missing Receipt has not been created for this Sales Order :   '
                      || l_aopspay_tab (i).order_number
                     );
               WHEN OTHERS
               THEN
                  ln_cash_rec_id := -3;
                  put_log_line (p_debug_flag,
                                'N',
                                   ' Exception raised at ln_cash_rec_id'
                                || SQLERRM
                               );
            END;

            IF ln_cash_rec_id <> -3
            THEN
               fnd_file.put_line
                  (fnd_file.LOG,
                      ' Receipt # '
                   || l_receipt_number
                   || ' has been created Successfully for this Sales Order # '
                   || l_aopspay_tab (i).order_number
                  );
               l_tot_rec := l_tot_rec + 1;
            -- Gayathri added below Code added as part of 23068
            END IF;
         END LOOP;

         put_log_line
            (p_debug_flag,
             'N',
                ' Total Number of Missing Receipts Created Successfully are :  '
             || l_tot_rec
             || ' out of the Missing Receipts '
             || l_aopspay_tab.COUNT
            );
      END IF;

      put_log_line (p_debug_flag,
                    'N',
                    'End ofthe XX_CREATE_MISSING_RECEIPT Procedure:  '
                   );
   END xx_create_missing_receipt;

   -- SAS Pending Deposit Hold Records
   PROCEDURE xx_om_sas_depo_release (
      p_order_number_from   IN   NUMBER,
      p_order_number_to     IN   NUMBER,
      p_date_from           IN   VARCHAR2,
      p_date_to             IN   VARCHAR2,
      p_debug_flag          IN   VARCHAR2 DEFAULT 'N'
   )
   AS
-- +=====================================================================+
-- | Name  : XX_OM_SAS_DEPO_RELEASE                                      |
-- | Description     : The Process Child is called to release holds on   |
-- |                   records stuck with hold name as                   |
-- |                   OD: SAS Pending deposit hold                      |
-- | Parameters      : p_order_number_from IN ->Order Number             |
-- |                   P_ORDER_NUMBER_TO   IN ->Order Number             |
-- |                   P_date_FROM         IN ->Date Range(From)         |
-- |                   p_date_to           IN ->Date Range(To)           |
-- |                   p_debug_flag        IN ->Debug flag               |
-- |                                           By default it will be N.  |
-- +=====================================================================+
      l_hold_source_rec    oe_holds_pvt.hold_source_rec_type;
      l_hold_release_rec   oe_holds_pvt.hold_release_rec_type;
      l_header_rec         xx_om_sacct_conc_pkg.header_match_rec;
      i                    BINARY_INTEGER;
      ln_header_id         oe_order_headers_all.header_id%TYPE;
	  ln_cash_receipt		ar_cash_receipts_all.cash_receipt_id%TYPE;	--Defect#39944
      lc_return_status     VARCHAR2 (30);
      ln_msg_count         NUMBER;
      ln_sucess_count      NUMBER                                := 0;
      ln_fetch_count       NUMBER                                := 0;
      ln_total_fetch       NUMBER                                := 0;
      ln_failed_count      NUMBER                                := 0;
      lc_msg_data          VARCHAR2 (2000);
      ln_prepaid_amount    NUMBER                                := 0;
      ln_order_total       NUMBER                                := 0;
      ln_avail_balance     NUMBER                                := 0;
      ln_hold_id           NUMBER                                := 0;
      ln_r_msg_count       NUMBER                                := 0;
      ln_payment_set_id    NUMBER;
      ln_amount            NUMBER;
      ln_ord_due_balance   NUMBER;
      ln_sent_amt          NUMBER;
      ln_amount_applied    NUMBER;
      ln_osr_length        NUMBER                                := 0;
      l_date_to            DATE
          := fnd_conc_date.string_to_date (p_date_to) + 1
             - 1 / (24 * 60 * 60);
      l_date_from          DATE := fnd_conc_date.string_to_date (p_date_from);
      l_single_pay         VARCHAR2 (5);        /*Added for defect  #27876 */
      l_avail_bal          NUMBER                                := 0;
                                                /*Added for defect  #27876 */
      l_avail_bal1         NUMBER                                := 0;
                                                /*Added for defect  #27876 */
      
      

      -- this cursor pulls up all orders in entered and invoice hold status which has
      -- a deposit with status as "CREATED_DEPOSIT".
      CURSOR c_order_number
      IS
         SELECT DISTINCT h.header_id--, d.cash_receipt_id		--Defect#39944
                    FROM oe_order_headers_all h,
                         oe_order_holds_all oh,
                         oe_hold_sources_all hs,
                         oe_hold_definitions hd,
                         xx_om_legacy_deposits d,
                         xx_om_legacy_dep_dtls dd
                   WHERE h.header_id = oh.header_id
                     AND oh.hold_source_id = hs.hold_source_id
                     AND h.org_id = g_org_id
                     AND hs.hold_id = hd.hold_id
                     AND oh.hold_release_id IS NULL
                     AND hd.NAME = 'OD: SAS Pending deposit hold'
                     AND d.i1025_status IN
                                      ('STD_PREPAY_MATCH', 'CREATED_DEPOSIT')
                     AND d.cash_receipt_id IS NOT NULL
                     AND SUBSTR (h.orig_sys_document_ref, 1, 9) =
                                       SUBSTR (dd.orig_sys_document_ref, 1, 9)
                     AND LENGTH (dd.orig_sys_document_ref) = 12
                     AND dd.transaction_number = d.transaction_number
                     AND h.flow_status_code IN ('ENTERED', 'INVOICE_HOLD')
                     AND h.order_number BETWEEN NVL (p_order_number_from,
                                                     h.order_number
                                                    )
                                            AND NVL (p_order_number_to,
                                                     h.order_number
                                                    )
                     AND h.creation_date BETWEEN NVL (l_date_from,
                                                      h.creation_date
                                                     )
                                             AND NVL (l_date_to,
                                                      h.creation_date
                                                     )
         UNION
         SELECT DISTINCT h.header_id--, d.cash_receipt_id		--Defect#39944
                    FROM oe_order_headers_all h,
                         oe_order_holds_all oh,
                         oe_hold_sources_all hs,
                         oe_hold_definitions hd,
                         xx_om_legacy_deposits d,
                         xx_om_legacy_dep_dtls dd
                   WHERE h.header_id = oh.header_id
                     AND oh.hold_source_id = hs.hold_source_id
                     AND hs.hold_id = hd.hold_id
                     AND h.org_id = g_org_id
                     AND oh.hold_release_id IS NULL
                     AND hd.NAME = 'OD: SAS Pending deposit hold'
                     AND d.i1025_status IN
                                      ('STD_PREPAY_MATCH', 'CREATED_DEPOSIT')
                     AND d.cash_receipt_id IS NOT NULL
                     AND h.orig_sys_document_ref = dd.orig_sys_document_ref
                     AND LENGTH (dd.orig_sys_document_ref) = 20
                     AND dd.transaction_number = d.transaction_number
                     AND h.flow_status_code IN ('ENTERED', 'INVOICE_HOLD')
                     AND h.order_number BETWEEN NVL (p_order_number_from,
                                                     h.order_number
                                                    )
                                            AND NVL (p_order_number_to,
                                                     h.order_number
                                                    )
                     AND h.creation_date BETWEEN NVL (l_date_from,
                                                      h.creation_date
                                                     )
                                             AND NVL (l_date_to,
                                                      h.creation_date
                                                     );

      -- This cursor pulls required info from deposit record to insert into payments table
      CURSOR c_payment (p_header_id IN NUMBER)
      IS
         SELECT DISTINCT h.header_id header_id, h.request_id request_id,
                         d.payment_type_code payment_type_code,
                         d.credit_card_code credit_card_code,
                         d.credit_card_number credit_card_number,
                         d.credit_card_holder_name credit_card_holder_name,
                         d.credit_card_expiration_date
                                                  credit_card_expiration_date,
                         d.payment_set_id payment_set_id,
                         d.receipt_method_id receipt_method_id,
                         d.payment_collection_event payment_collection_event,
                         d.credit_card_approval_code
                                                    credit_card_approval_code,
                         d.credit_card_approval_date
                                                    credit_card_approval_date,
                         d.check_number check_number,
                         d.orig_sys_payment_ref orig_sys_payment_ref,
                         TO_NUMBER (d.orig_sys_payment_ref) payment_number,
                         dd.orig_sys_document_ref orig_sys_document_ref,
                         d.avail_balance avail_balance,
                         d.prepaid_amount prepaid_amount,
                         d.cc_auth_manual attribute6,
                         d.merchant_number attribute7,
                         d.cc_auth_ps2000 attribute8, d.allied_ind attribute9,
                         d.cc_mask_number attribute10,
                         d.od_payment_type attribute11,
                         d.debit_card_approval_ref attribute12,
                            d.cc_entry_mode
                         || ':'
                         || d.cvv_resp_code
                         || ':'
                         || d.avs_resp_code
                         || ':'
                         || d.auth_entry_mode attribute13,
                         d.cash_receipt_id attribute15,
                         d.transaction_number tran_number,   /* Added by NB */
                         d.single_pay_ind        /*Added for defect  #27876 */,
						 d.token_flag    /* Added for defect 37647 and version 1.6*/
						
                    FROM oe_order_headers_all h,
                         xx_om_legacy_deposits d,
                         xx_om_legacy_dep_dtls dd
                   WHERE LENGTH (dd.orig_sys_document_ref) = 12
                     AND SUBSTR (h.orig_sys_document_ref, 1, 9) =
                                                            SUBSTR (dd.orig_sys_document_ref(+),
                                                                    1, 9)
                     AND NVL (d.error_flag, 'N') = 'N'
                     AND dd.transaction_number = d.transaction_number
                     AND d.avail_balance > 0
                     AND h.header_id = p_header_id
         UNION
         SELECT DISTINCT h.header_id header_id, h.request_id request_id,
                         d.payment_type_code payment_type_code,
                         d.credit_card_code credit_card_code,
                         d.credit_card_number credit_card_number,
                         d.credit_card_holder_name credit_card_holder_name,
                         d.credit_card_expiration_date
                                                  credit_card_expiration_date,
                         d.payment_set_id payment_set_id,
                         d.receipt_method_id receipt_method_id,
                         d.payment_collection_event payment_collection_event,
                         d.credit_card_approval_code
                                                    credit_card_approval_code,
                         d.credit_card_approval_date
                                                    credit_card_approval_date,
                         d.check_number check_number,
                         d.orig_sys_payment_ref orig_sys_payment_ref,
                         TO_NUMBER (d.orig_sys_payment_ref) payment_number,
                         dd.orig_sys_document_ref orig_sys_document_ref,
                         d.avail_balance avail_balance,
                         d.prepaid_amount prepaid_amount,
                         d.cc_auth_manual attribute6,
                         d.merchant_number attribute7,
                         d.cc_auth_ps2000 attribute8, d.allied_ind attribute9,
                         d.cc_mask_number attribute10,
                         d.od_payment_type attribute11,
                         d.debit_card_approval_ref attribute12,
                            d.cc_entry_mode
                         || ':'
                         || d.cvv_resp_code
                         || ':'
                         || d.avs_resp_code
                         || ':'
                         || d.auth_entry_mode attribute13,
                         d.cash_receipt_id attribute15,
                         d.transaction_number tran_number,   /* Added by NB */
                         d.single_pay_ind        /*Added for defect  #27876 */,
						 d.token_flag    /* Added for defect 37647 and version 1.6*/
                    FROM oe_order_headers_all h,
                         xx_om_legacy_deposits d,
                         xx_om_legacy_dep_dtls dd
                   WHERE h.orig_sys_document_ref = dd.orig_sys_document_ref
                     AND NVL (d.error_flag, 'N') = 'N'
                     AND LENGTH (dd.orig_sys_document_ref) = 20
                     AND d.avail_balance > 0
                     AND dd.transaction_number = d.transaction_number
                     AND h.header_id = p_header_id
                ORDER BY avail_balance;          /*Added for defect  #27876 */

      TYPE t_order_tab IS TABLE OF c_order_number%ROWTYPE
         INDEX BY PLS_INTEGER;

      l_order_tab          t_order_tab;
      
     /*Added for defect  #27876 */
      TYPE t_payment_tab IS TABLE OF c_payment%ROWTYPE
         INDEX BY PLS_INTEGER;
      
      l_payment_tab   t_payment_tab;
 /*End of code changes for Defect# 27876     */
      -- reterives the holds info
      CURSOR c_hold (p_header_id IN NUMBER)
      IS
         SELECT oh.header_id, hs.hold_id, hs.hold_source_id, oh.order_hold_id
           FROM oe_order_holds_all oh, oe_hold_sources_all hs
          WHERE oh.hold_source_id = hs.hold_source_id
            AND oh.hold_release_id IS NULL
            AND oh.header_id = p_header_id;
   BEGIN
      put_log_line (p_debug_flag,
                    'Y',
                    'OD: OM Release Deposit Holds ' || CHR (10)
                   );
      put_log_line (p_debug_flag,
                    'Y',
                       'Concurrent Program Parameters                  :::'
                    || CHR (10)
                   );
      put_log_line (p_debug_flag,
                    'Y',
                       'Order Number From                           :::'
                    || '  '
                    || p_order_number_from
                    || CHR (10)
                   );
      put_log_line (p_debug_flag,
                    'Y',
                       'Order Number To                             :::'
                    || '  '
                    || p_order_number_to
                    || CHR (10)
                   );
      put_log_line (p_debug_flag,
                    'Y',
                       'Order Date From                              :::'
                    || '  '
                    || l_date_from
                    || CHR (10)
                   );
      put_log_line (p_debug_flag,
                    'Y',
                       'Order Date To                                :::'
                    || '  '
                    || l_date_to
                    || CHR (10)
                   );
      put_log_line (p_debug_flag,
                    'Y',
                    'Release OD: SAS Pending deposit hold ' || '  '
                    || CHR (10)
                   );
      put_log_line (p_debug_flag, 'Y', ':::BEGIN:::');

      IF p_debug_flag = 'Y'
      THEN
         put_log_line (p_debug_flag,
                       'N',
                       'Value of g_org_id is :  ' || g_org_id
                      );
      END IF;

      OPEN c_order_number;

      FETCH c_order_number
      BULK COLLECT INTO l_order_tab;

      CLOSE c_order_number;

      ln_fetch_count := ln_fetch_count + 1;
      ln_total_fetch := l_order_tab.COUNT;
      put_log_line (p_debug_flag,
                    'Y',
                    'Total Fetched Orders::: ' || l_order_tab.COUNT
                   );

      IF (l_order_tab.COUNT > 0)
      THEN
         FOR i IN l_order_tab.FIRST .. l_order_tab.LAST
         LOOP
            ln_header_id := l_order_tab (i).header_id;
			--ln_cash_receipt := l_order_tab (i).cash_receipt_id; 	--Defect#39944
            l_header_rec := NULL;

            OPEN c_hold (ln_header_id);

            FETCH c_hold
            BULK COLLECT INTO l_header_rec.header_id, l_header_rec.hold_id,
                   l_header_rec.hold_source_id, l_header_rec.order_hold_id;

            CLOSE c_hold;

            IF p_debug_flag = 'Y'
            THEN
               put_log_line (p_debug_flag, 'N', ' ');
               put_log_line (p_debug_flag,
                             'N',
                                'l_header_rec.header_id:::'
                             || l_header_rec.header_id (1)
                            );
               put_log_line (p_debug_flag,
                             'N',
                             'ln_header_id:::' || ln_header_id
                            );
               put_log_line (p_debug_flag, 'N', ' ');
            END IF;

            IF l_header_rec.header_id (1) IS NOT NULL
            THEN
               -- Now Remove the hold on the order
               l_hold_source_rec.hold_source_id :=
                                              l_header_rec.hold_source_id (1);
               l_hold_source_rec.hold_id := l_header_rec.hold_id (1);
               l_hold_release_rec.release_reason_code :=
                                                 'MANUAL_RELEASE_MARGIN_HOLD';
               l_hold_release_rec.release_comment :=
                                                    'Post Production Cleanup';
               l_hold_release_rec.hold_source_id :=
                                              l_header_rec.hold_source_id (1);
               l_hold_release_rec.order_hold_id :=
                                               l_header_rec.order_hold_id (1);

               IF p_debug_flag = 'Y'
               THEN
                  put_log_line (p_debug_flag, 'N', ' ');
                  put_log_line (p_debug_flag,
                                'N',
                                   'HEADER_ID      : '
                                || l_header_rec.header_id (1)
                               );
                  put_log_line (p_debug_flag,
                                'N',
                                   'HOLD_SOURCE_ID : '
                                || l_header_rec.hold_source_id (1)
                               );
                  put_log_line (p_debug_flag,
                                'N',
                                'HOLD_ID : ' || l_header_rec.hold_id (1)
                               );
                  put_log_line (p_debug_flag, 'N', ' ');
               END IF;

               oe_holds_pub.release_holds
                                    (p_hold_source_rec       => l_hold_source_rec,
                                     p_hold_release_rec      => l_hold_release_rec,
                                     x_return_status         => lc_return_status,
                                     x_msg_count             => ln_msg_count,
                                     x_msg_data              => lc_msg_data
                                    );

               IF p_debug_flag = 'Y'
               THEN
                  put_log_line (p_debug_flag, 'N', ' ');
                  put_log_line (p_debug_flag,
                                'N',
                                'Hold Return Status::' || lc_return_status
                               );
                  put_log_line (p_debug_flag, 'N', ' ');
               END IF;
            -- COMMIT;  Defect#13407. The commit statement is stopping the ENTERED records from getting inserted into OE_PAYMENTS table.
            ELSE
               IF p_debug_flag = 'Y'
               THEN
                  put_log_line (p_debug_flag, 'N', ' ');
                  put_log_line (p_debug_flag, 'N', 'NO Hold is Applied ');
                  put_log_line (p_debug_flag, 'N', ' ');
               END IF;
            END IF;

            IF lc_return_status = 'S'
            THEN
               ln_ord_due_balance := NULL;

               IF p_debug_flag = 'Y'
               THEN
                  put_log_line (p_debug_flag, 'N', ' ');
                  put_log_line (p_debug_flag, 'N', 'before r_payment loop ');
                  put_log_line (p_debug_flag,
                                'N',
                                'ln_header_id ' || ln_header_id
                               );
                  put_log_line (p_debug_flag,
                                'N',
                                   'l_header_rec.header_id(1)  '
                                || l_header_rec.header_id (1)
                               );
                  put_log_line (p_debug_flag, 'N', ' ');
               END IF;

               ln_payment_set_id := NULL;
                /*Added for defect  #27876 */
                BEGIN
	                                  SELECT ROUND (order_total, 2) order_total
	                                    INTO ln_order_total
	                                    FROM xx_om_header_attributes_all
	                                   WHERE header_id = ln_header_id;
	       
	                                  IF p_debug_flag = 'Y'
	                                  THEN
	                                     put_log_line (p_debug_flag, 'N', ' ');
	                                     put_log_line (p_debug_flag,
	                                                   'N',
	                                                      'Outsie LOOP ln_order_total '
	                                                   || ln_order_total
	                                                  );
	                                     put_log_line (p_debug_flag, 'N', ' ');
                           END IF;
                         END;  
	       
	       
	       OPEN c_payment(l_header_rec.header_id (1));
	       
	             FETCH c_payment
	             BULK COLLECT INTO l_payment_tab;
	       
	             CLOSE c_payment;
	       
	           put_log_line (p_debug_flag,
	                           'Y',
	                           'Total Deposit payment lines::: ' || l_payment_tab.COUNT
                   );
	       
	        /*End of code changes for Defect# 27876     */

               FOR r_payment IN c_payment (l_header_rec.header_id (1))
               LOOP            
                  IF r_payment.prepaid_amount > 0
                  THEN
                     ln_header_id := r_payment.header_id;

                     IF p_debug_flag = 'Y'
                     THEN
                        put_log_line (p_debug_flag, 'N', ' ');
                        put_log_line (p_debug_flag,
                                      'N',
                                         'r_payment.prepaid_amount :  '
                                      || r_payment.prepaid_amount
                                     );
                        put_log_line (p_debug_flag,
                                      'N',
                                      'header_id :  ' || ln_header_id
                                     );
                        put_log_line (p_debug_flag,
                                      'N',
                                         'r_payment.header_id :  '
                                      || r_payment.header_id
                                     );
                        put_log_line (p_debug_flag,
                                      'N',
                                         'orig_sys_payment_ref :  '
                                      || r_payment.orig_sys_payment_ref
                                     );
                        put_log_line (p_debug_flag,
                                      'N',
                                         'payment_number :  '
                                      || r_payment.payment_number
                                     );
                        put_log_line (p_debug_flag, 'N', ' ');
                     END IF;

                     SELECT order_total
                       INTO ln_amount
                       FROM xx_om_header_attributes_all
                      WHERE header_id = r_payment.header_id;
					  
					 --Defect#39944
					 SELECT SUM (prepaid_amount)
                        INTO ln_prepaid_amount
                        FROM oe_payments
                        WHERE header_id = ln_header_id
                        AND prepaid_amount > 0;
						
					IF (ln_amount = ln_prepaid_amount)
					THEN
							IF p_debug_flag = 'Y'
							THEN
								put_log_line (p_debug_flag, 'N', ' ');
								put_log_line (p_debug_flag,
											'N',
											'Complete payment has been created successfully.'
											);
							END IF;
							
							GOTO skip_payment;
					END IF;
					--Defect#39944

                     l_single_pay := r_payment.single_pay_ind;
                     /*Added for defect  #27876 */
                     l_avail_bal := r_payment.avail_balance;
                    

                     IF p_debug_flag = 'Y'
                     THEN
                        put_log_line (p_debug_flag, 'N', ' ');
                        put_log_line (p_debug_flag,
                                      'N',
                                      'ln_amount ' || ln_amount
                                     );
                        put_log_line (p_debug_flag,
                                      'N',
                                         'avail_balance  '
                                      || r_payment.avail_balance
                                     );
                        put_log_line (p_debug_flag, 'N', ' ');
                     END IF;

                     BEGIN
                        SELECT amount_applied
                          INTO ln_amount_applied
                          FROM ar_receivable_applications_all
                         WHERE cash_receipt_id = r_payment.attribute15
                           AND application_ref_num = r_payment.tran_number
                           AND application_ref_type = 'SA'
                           AND display = 'Y';
                     EXCEPTION
                        WHEN OTHERS
                        THEN
                           ln_amount_applied := 0;
                     END;
					 
					 IF p_debug_flag = 'Y'
                     THEN
                        put_log_line (p_debug_flag, 'N', ' ');
                        put_log_line (p_debug_flag,
                                      'N',
                                      'ln_amount_applied ' || ln_amount_applied
                                     );
                     END IF;	--Defect#39944

                     IF ln_amount <= r_payment.avail_balance
                     THEN
                        IF ln_ord_due_balance IS NULL
                        THEN
                           ln_ord_due_balance :=
                                       (ln_amount - r_payment.avail_balance
                                       );
                           ln_sent_amt := ln_amount;
                        ELSE
                           ln_sent_amt := ln_ord_due_balance;
                        END IF;
                     ELSE
                        IF (ln_ord_due_balance IS NULL OR r_payment.avail_balance < ln_ord_due_balance)
                        THEN
                           ln_sent_amt := r_payment.avail_balance;
                           ln_ord_due_balance :=
                              (  NVL (ln_ord_due_balance, ln_amount)
                               - r_payment.avail_balance
                              );
                        ELSE
                           ln_sent_amt := ln_ord_due_balance;
                           ln_ord_due_balance :=
                              (  NVL (ln_ord_due_balance, ln_amount)
                               - r_payment.avail_balance
                              );
                        END IF;	--Defect#39944
						/*ln_sent_amt := r_payment.avail_balance;
                           ln_ord_due_balance :=
                              (  NVL (ln_ord_due_balance, ln_amount)
                               - r_payment.avail_balance
                              );	*/	--Defect#39944
						
                     END IF;
					 
					 IF p_debug_flag = 'Y'
                     THEN
                        put_log_line (p_debug_flag, 'N', ' ');
                        put_log_line (p_debug_flag,
                                      'N',
                                      'ln_sent_amt  ' || ln_sent_amt
                                     );
                        put_log_line (p_debug_flag,
                                      'N',
                                         'ln_ord_due_balance  '
                                      || ln_ord_due_balance
                                     );
                        put_log_line (p_debug_flag, 'N', ' ');
                     END IF;		--Defect#39944

                     IF ln_amount_applied < ln_sent_amt
                     THEN
                        IF p_debug_flag = 'Y'
                        THEN
                           put_log_line (p_debug_flag, 'N', ' ');
                           put_log_line
                               (p_debug_flag,
                                'N',
                                'Amount to Apply is less then send amount   '
                               );
                           put_log_line (p_debug_flag, 'N', ' ');
                        END IF;

                        GOTO end_of_loop;
                     END IF;

                     IF ln_sent_amt <= 0
                     THEN
                        IF p_debug_flag = 'Y'
                        THEN
                           put_log_line (p_debug_flag, 'N', ' ');
                           put_log_line
                              (p_debug_flag,
                               'N',
                                  'Order total is less then avaliable balance :  '
                               || r_payment.attribute15
                              );
                           put_log_line (p_debug_flag, 'N', ' ');
                        END IF;

                        GOTO end_of_loop;
                     ELSE
                        IF p_debug_flag = 'Y'
                        THEN
                           put_log_line (p_debug_flag, 'N', ' ');
                           put_log_line
                               (p_debug_flag,
                                'N',
                                   'UNAPPLY APPLY TRANSACTION RECEIPT ID :  '
                                || r_payment.attribute15
                               );
                           put_log_line (p_debug_flag, 'N', ' ');
                        END IF;
                     END IF;

                     IF p_debug_flag = 'Y'
                     THEN
                        put_log_line (p_debug_flag, 'N', ' ');
                        put_log_line (p_debug_flag,
                                      'N',
                                         'r_payment.orig_sys_document_ref  '
                                      || r_payment.orig_sys_document_ref
                                     );
                        put_log_line (p_debug_flag,
                                      'N',
                                         'cash receipt id '
                                      || r_payment.attribute15
                                     );                                     
                        put_log_line (p_debug_flag, 'N', ' ');   
                     END IF;

                     xx_ar_prepayments_pkg.reapply_deposit_prepayment
                           (p_init_msg_list         => fnd_api.g_true,
                            p_commit                => fnd_api.g_false,
                            p_validation_level      => fnd_api.g_valid_level_full,
                            p_cash_receipt_id       => r_payment.attribute15,
                            p_header_id             => r_payment.header_id,
                            p_order_number          => r_payment.orig_sys_document_ref,
                            p_apply_amount          => ln_sent_amt,
                            x_payment_set_id        => ln_payment_set_id,
                            x_return_status         => lc_return_status,
                            x_msg_count             => ln_r_msg_count,
                            x_msg_data              => lc_msg_data
                           );

                     IF p_debug_flag = 'Y'
                     THEN
                        put_log_line (p_debug_flag, 'N', ' ');
                        put_log_line
                           (p_debug_flag,
                            'N',
                            'after calling XX_AR_PREPAYMENTS_PKG.reapply_deposit_prepayment '
                           );
                        put_log_line (p_debug_flag,
                                      'N',
                                      'lc_return_status ' || lc_return_status
                                     );
                        put_log_line (p_debug_flag, 'N', ' ');
                     END IF;

                     IF lc_return_status = 'S'
                     THEN
                        IF p_debug_flag = 'Y'
                        THEN
                           put_log_line (p_debug_flag, 'N', ' ');
                           put_log_line (p_debug_flag,
                                         'N',
                                            'ln_payment_set_id : '
                                         || ln_payment_set_id
                                        );
                           put_log_line (p_debug_flag, 'N', ' ');
                        END IF;
                     ELSE
                        IF ln_r_msg_count >= 1
                        THEN
                           FOR i IN 1 .. ln_msg_count
                           LOOP
                              put_log_line
                                 ('N',
                                  'N',
                                     i
                                  || '. '
                                  || SUBSTR
                                        (fnd_msg_pub.get
                                                 (p_encoded      => fnd_api.g_false),
                                         1,
                                         255
                                        )
                                 );

                              IF p_debug_flag = 'Y'
                              THEN
                                 put_log_line (p_debug_flag, 'N', ' ');
                                 put_log_line
                                    (p_debug_flag,
                                     'N',
                                     'raised error and skipping the payment   '
                                    );
                                 put_log_line (p_debug_flag, 'N', ' ');
                              END IF;

                              GOTO skip_payment;
                           END LOOP;
                        END IF;
                     END IF;

                     BEGIN
                        IF p_debug_flag = 'Y'
                        THEN
                           put_log_line (p_debug_flag, 'N', ' ');
                           put_log_line (p_debug_flag,
                                         'N',
                                         'before inserting into oe_payments '
                                        );
                           put_log_line (p_debug_flag, 'N', ' ');
                        END IF;

                        INSERT INTO oe_payments
                                    (payment_level_code, header_id,
                                     creation_date, created_by,
                                     last_update_date, last_updated_by,
                                     request_id,
                                     payment_type_code,
                                     credit_card_code,
                                     credit_card_number,
                                     credit_card_holder_name,
                                     credit_card_expiration_date,
                                     prepaid_amount, payment_set_id,
                                     receipt_method_id,
                                     payment_collection_event,
                                     credit_card_approval_code,
                                     credit_card_approval_date,
                                     check_number, payment_amount,
                                     payment_number, lock_control,
                                     orig_sys_payment_ref,
                                     CONTEXT, attribute6,
                                     attribute7,
                                     attribute8,
                                     attribute9,
                                     attribute10,
                                     attribute11,
                                     attribute12,
                                     attribute13,
									 attribute3, /* Added as part of defect 37647 and version 1.6 */
                                     attribute15
                                    )
                             VALUES ('ORDER', ln_header_id,
                                     SYSDATE, fnd_global.user_id,
                                     SYSDATE, fnd_global.user_id,
                                     r_payment.request_id,
                                     r_payment.payment_type_code,
                                     r_payment.credit_card_code,
                                     r_payment.credit_card_number,
                                     r_payment.credit_card_holder_name,
                                     r_payment.credit_card_expiration_date,
                                     ln_sent_amt, ln_payment_set_id,
                                     r_payment.receipt_method_id,
                                     'PREPAY',
                                     r_payment.credit_card_approval_code,
                                     r_payment.credit_card_approval_date,
                                     r_payment.check_number, ln_sent_amt,
                                     r_payment.payment_number, 1,
                                     r_payment.orig_sys_payment_ref,
                                     'SALES_ACCT_HVOP', r_payment.attribute6,
                                     r_payment.attribute7,
                                     r_payment.attribute8,
                                     r_payment.attribute9,
                                     r_payment.attribute10,
                                     r_payment.attribute11,
                                     r_payment.attribute12,
                                     r_payment.attribute13,
									 r_payment.token_flag, /* Added as part of defect 37647 and version 1.6 */
                                     r_payment.attribute15
                                    );

                        put_log_line ('Y', 'N', 'after insertion ');
                        COMMIT;
                     EXCEPTION
                        WHEN OTHERS
                        THEN
                           put_log_line
                                  (p_debug_flag,
                                   'Y',
                                      'Trying to insert Duplicate Payment:::'
                                   || r_payment.orig_sys_document_ref
                                   || SQLERRM
                                  );
                           GOTO skip_payment;
                     END;
                  END IF;

                  /* Added for defect #27876*/
                  IF (l_payment_tab.COUNT > 1)
     			 THEN
                     IF r_payment.single_pay_ind = 'Y'
                     THEN                      

                           SELECT SUM (prepaid_amount)
                             INTO ln_prepaid_amount
                             FROM oe_payments
                            WHERE header_id = ln_header_id
                              AND prepaid_amount > 0;

                           IF p_debug_flag = 'Y'
                           THEN
                              put_log_line (p_debug_flag, 'N', ' ');
                              put_log_line
                                         (p_debug_flag,
                                          'N',
                                             'Inside LOOP ln_prepaid_amount '
                                          || ln_prepaid_amount
                                         );
                              put_log_line (p_debug_flag, 'N', ' ');
                           END IF;
                        

                        IF ln_order_total <= r_payment.avail_balance
                        THEN
                           IF p_debug_flag = 'Y'
                           THEN
                              put_log_line (p_debug_flag, 'N', ' ');
                              put_log_line (p_debug_flag,
                                            'N',
                                               'entered into 1st loop '
                                            || l_avail_bal
                                           );
                              put_log_line (p_debug_flag, 'N', ' ');
                           END IF;

                           ln_prepaid_amount := ln_order_total;
                           -- Order Total is matched by the availbale balance
                           l_avail_bal1 :=
                                      r_payment.avail_balance - ln_order_total;
                           ln_order_total := 0;
                           
                        ELSE
                           IF p_debug_flag = 'Y'
                           THEN
                              put_log_line (p_debug_flag, 'N', ' ');
                              put_log_line
                                 (p_debug_flag,
                                  'N',
                                     'entered into 1st else loop inside loop '
                                  || l_avail_bal
                                 );
                              put_log_line (p_debug_flag, 'N', ' ');
                           END IF;

                           ln_prepaid_amount := r_payment.avail_balance;
                           -- Set the remaining balance
                           ln_order_total :=
                                      ln_order_total - r_payment.avail_balance;
                           l_avail_bal1 := 0;
                        END IF;
                       

                        UPDATE xx_om_legacy_deposits d
                           SET d.avail_balance = l_avail_bal1,
                               last_update_date = SYSDATE,
                               last_updated_by = fnd_global.user_id
                         WHERE prepaid_amount > 0
                           AND cash_receipt_id = r_payment.attribute15;
                     END IF;
                  END IF;
			 /* Added for defect #27876*/
                  <<end_of_loop>>
                  IF p_debug_flag = 'Y'
                  THEN
                     put_log_line (p_debug_flag, 'N', ' ');
                     put_log_line (p_debug_flag, 'N', 'END OF LOOP ');
                     put_log_line (p_debug_flag, 'N', ' ');
                  END IF;
               END LOOP;

               <<skip_payment>>
               SELECT SUM (prepaid_amount)
                 INTO ln_prepaid_amount
                 FROM oe_payments
                WHERE header_id = ln_header_id AND prepaid_amount > 0;

               IF p_debug_flag = 'Y'
               THEN
                  put_log_line (p_debug_flag, 'N', ' ');
                  put_log_line (p_debug_flag,
                                'N',
                                'ln_prepaid_amount ' || ln_prepaid_amount
                               );
                  put_log_line (p_debug_flag, 'N', ' ');
               END IF;

               SELECT LENGTH (orig_sys_document_ref)
                 INTO ln_osr_length
                 FROM oe_order_headers_all
                WHERE header_id = ln_header_id;

               SELECT ROUND (order_total, 2) order_total
                 INTO ln_order_total
                 FROM xx_om_header_attributes_all
                WHERE header_id = ln_header_id;

               IF p_debug_flag = 'Y'
               THEN
                  put_log_line (p_debug_flag, 'N', ' ');
                  put_log_line (p_debug_flag,
                                'N',
                                'ln_order_total ' || ln_order_total
                               );
                  put_log_line (p_debug_flag, 'N', ' ');
               END IF;

               IF ln_prepaid_amount = ln_order_total
               THEN
                  put_log_line ('N', 'N', 'Avail Balance IS 0 ');

                  /* Added for defect #27876*/
                  IF l_single_pay = 'Y'
                  THEN
                      IF (l_payment_tab.COUNT = 1)
     			 THEN
                        IF l_avail_bal < ln_order_total
                        THEN
                           IF p_debug_flag = 'Y'
                           THEN
                              put_log_line (p_debug_flag, 'N', ' ');
                              put_log_line
                                 (p_debug_flag,
                                  'N',
                                  'Amount to Apply is less then Order Total  '
                                 );
                              put_log_line (p_debug_flag, 'N', ' ');
                           END IF;

                           GOTO end_of_loop;
                        ELSE
                           UPDATE xx_om_legacy_deposits d
                              SET d.avail_balance =
                                              d.avail_balance - ln_order_total
                            WHERE prepaid_amount > 0
							--and  d.cash_receipt_id = ln_cash_receipt	--Defect#39944
                              AND EXISTS (
                                     SELECT 1
                                       FROM oe_order_headers_all h,
                                            xx_om_legacy_dep_dtls dd
                                      WHERE h.header_id = ln_header_id
                                        AND h.orig_sys_document_ref =
                                                      dd.orig_sys_document_ref
                                        AND dd.transaction_number =
                                                          d.transaction_number);
                        END IF;
                     END IF;
                  /*End of code changes for Defect# 27876     */
                  ELSIF ln_osr_length = 12
                  THEN
                     UPDATE xx_om_legacy_deposits d
                        SET avail_balance = 0
                      WHERE PREPAID_AMOUNT > 0
					  and  d.cash_receipt_id = ln_cash_receipt	--Defect#39944
                        AND EXISTS (
                               SELECT 1
                                 FROM oe_order_headers_all h,
                                      xx_om_legacy_dep_dtls dd
                                WHERE h.header_id = ln_header_id
                                  AND SUBSTR (h.orig_sys_document_ref, 1, 9) =
                                         SUBSTR (dd.orig_sys_document_ref,
                                                 1,
                                                 9
                                                )
                                  AND LENGTH (dd.orig_sys_document_ref) = 12
                                  AND dd.transaction_number =
                                                          d.transaction_number);
                  ELSIF ln_osr_length = 20
                  THEN
                     UPDATE xx_om_legacy_deposits d
                        SET avail_balance = 0
                      WHERE prepaid_amount > 0
					  --and  d.cash_receipt_id = ln_cash_receipt	--Defect#39944
                        AND EXISTS (
                               SELECT 1
                                 FROM oe_order_headers_all h,
                                      xx_om_legacy_dep_dtls dd
                                WHERE h.header_id = ln_header_id
                                  AND h.orig_sys_document_ref =
                                                      dd.orig_sys_document_ref
                                  AND LENGTH (dd.orig_sys_document_ref) = 20
                                  AND dd.transaction_number =
                                                          d.transaction_number);
                  END IF;

                  COMMIT;
                  wf_engine.completeactivityinternalname
                                        (itemtype      => 'OEOH',
                                         itemkey       => l_header_rec.header_id
                                                                           (1),
                                         activity      => 'BOOK_ELIGIBLE',
                                         RESULT        => NULL
                                        );
                  ln_sucess_count := ln_sucess_count + 1;
                  COMMIT;
               ELSE
                  ln_avail_balance := ln_order_total - ln_prepaid_amount;

                  IF p_debug_flag = 'Y'
                  THEN
                     put_log_line (p_debug_flag, 'N', ' ');
                     put_log_line (p_debug_flag,
                                   'N',
                                   'ln_avail_balance : ' || ln_avail_balance
                                  );
                     put_log_line (p_debug_flag, 'N', ' ');
                  END IF;

                  /* Added for defect #27876*/
                  IF l_single_pay = 'Y'
                  THEN
                      IF (l_payment_tab.COUNT = 1)
     			 THEN
                        IF l_avail_bal < ln_order_total
                        THEN
                           IF p_debug_flag = 'Y'
                           THEN
                              put_log_line (p_debug_flag, 'N', ' ');
                              put_log_line
                                 (p_debug_flag,
                                  'N',
                                  'Amount to Apply is less then Order Total  '
                                 );
                              put_log_line (p_debug_flag, 'N', ' ');
                           END IF;

                           GOTO end_of_loop;
                        ELSE
                           UPDATE xx_om_legacy_deposits d
                              SET d.avail_balance =
                                              d.avail_balance - ln_order_total
                            WHERE prepaid_amount > 0
							--and  d.cash_receipt_id = ln_cash_receipt	--Defect#39944
                              AND EXISTS (
                                     SELECT 1
                                       FROM oe_order_headers_all h,
                                            xx_om_legacy_dep_dtls dd
                                      WHERE h.header_id = ln_header_id
                                        AND h.orig_sys_document_ref =
                                                      dd.orig_sys_document_ref
                                        AND dd.transaction_number =
                                                          d.transaction_number);
                        END IF;
                     END IF;
                  /*End of code changes for Defect# 27876*/
                  ELSIF ln_avail_balance > 0
                  THEN
                     IF p_debug_flag = 'Y'
                     THEN
                        put_log_line (p_debug_flag, 'N', ' ');
                        put_log_line (p_debug_flag,
                                      'N',
                                         'ln_avail_balance 2: '
                                      || ln_avail_balance
                                     );
                        put_log_line (p_debug_flag, 'N', ' ');
                     END IF;

                     IF ln_osr_length = 12
                     THEN
                        UPDATE xx_om_legacy_deposits d
                           SET avail_balance = ln_avail_balance
                         WHERE PREPAID_AMOUNT > 0
						 --and  d.cash_receipt_id = ln_cash_receipt	--Defect#39944
                           AND EXISTS (
                                  SELECT 1
                                    FROM oe_order_headers_all h,
                                         xx_om_legacy_dep_dtls dd
                                   WHERE h.header_id = ln_header_id
                                     AND SUBSTR (h.orig_sys_document_ref, 1,
                                                 9) =
                                            SUBSTR (dd.orig_sys_document_ref,
                                                    1,
                                                    9
                                                   )
                                     AND LENGTH (dd.orig_sys_document_ref) =
                                                                            12
                                     AND dd.transaction_number =
                                                          d.transaction_number);
                     ELSIF ln_osr_length = 20
                     THEN
                        UPDATE xx_om_legacy_deposits d
                           SET avail_balance = ln_avail_balance
                         WHERE PREPAID_AMOUNT > 0
						 --and  d.cash_receipt_id = ln_cash_receipt	--Defect#39944
                           AND EXISTS (
                                  SELECT 1
                                    FROM oe_order_headers_all h,
                                         xx_om_legacy_dep_dtls dd
                                   WHERE h.header_id = ln_header_id
                                     AND h.orig_sys_document_ref =
                                                      dd.orig_sys_document_ref
                                     AND LENGTH (dd.orig_sys_document_ref) =
                                                                            20
                                     AND dd.transaction_number =
                                                          d.transaction_number);
                     END IF;

                     SELECT hold_id
                       INTO ln_hold_id
                       FROM oe_hold_definitions
                      WHERE NAME = 'OD: SAS Pending deposit hold';

                     l_hold_source_rec.hold_id := ln_hold_id;
                     l_hold_source_rec.hold_entity_code := 'O';
                     l_hold_source_rec.hold_entity_id := ln_header_id;
                     l_hold_source_rec.hold_comment :=
                                                 SUBSTR (lc_msg_data, 1, 2000);
                     oe_holds_pub.apply_holds
                            (p_api_version           => 1.0,
                             p_validation_level      => fnd_api.g_valid_level_none,
                             p_hold_source_rec       => l_hold_source_rec,
                             x_msg_count             => ln_msg_count,
                             x_msg_data              => lc_msg_data,
                             x_return_status         => lc_return_status
                            );
                  END IF;
               END IF;
            END IF;

            COMMIT;

            /* Added for defect #27876*/
            <<end_of_loop>>
            IF p_debug_flag = 'Y'
            THEN
               oe_holds_pub.apply_holds
                           (p_api_version           => 1.0,
                            p_validation_level      => fnd_api.g_valid_level_none,
                            p_hold_source_rec       => l_hold_source_rec,
                            x_msg_count             => ln_msg_count,
                            x_msg_data              => lc_msg_data,
                            x_return_status         => lc_return_status
                           );
               put_log_line (p_debug_flag, 'N', ' ');
               put_log_line (p_debug_flag, 'N', 'END OF LOOP 2');
               put_log_line (p_debug_flag, 'N', ' ');
            END IF;                 /* End of code change for defect # 27876*/
         END LOOP;
      END IF;

      ln_failed_count := ln_total_fetch - ln_sucess_count;

      IF p_debug_flag = 'Y'
      THEN
         put_log_line (p_debug_flag, 'N', ' ');
         put_log_line (p_debug_flag,
                       'N',
                          'Sucessfully processed order Count:::'
                       || ln_sucess_count
                      );
         put_log_line (p_debug_flag,
                       'N',
                       'Failed to process order Count:::' || ln_failed_count
                      );
         put_log_line (p_debug_flag, 'N', ' ');
      END IF;

      put_log_line ('N', 'N', ':::End of Program:::');
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         put_log_line (p_debug_flag, 'Y', 'No Data Found To Process:::');
      WHEN OTHERS
      THEN
         put_log_line (p_debug_flag, 'Y', 'When Others Raised: ' || SQLERRM);
   END;

-- Payment Processing Failure Hold Records
   PROCEDURE xx_om_ppf_hold_release (
      p_order_number_from   IN   NUMBER,
      p_order_number_to     IN   NUMBER,
      p_date_from           IN   VARCHAR2,
      p_date_to             IN   VARCHAR2,
      p_debug_flag          IN   VARCHAR2 DEFAULT 'N'
   )
   AS
-- +=====================================================================+
-- | Name  : XX_OM_PPF_HOLD_RELEASE                                      |
-- | Description     : The Process Child is called to release holds on   |
-- |                   records stuck with hold name as                   |
-- |                   OD: Payment Processing Failure                    |
-- | Parameters      : p_order_number_from IN ->Order Number             |
-- |                   P_ORDER_NUMBER_TO   IN ->Order Number             |
-- |                   P_date_FROM         IN ->Date Range(From)         |
-- |                   p_date_to           IN ->Date Range(To)           |
-- |                   p_debug_flag        IN ->Debug flag               |
-- |                                           By default it will be N.  |
-- |                           As part of Defect # 23068                 |
-- |      included Entered Status in the XX_OM_PPF_HOLD_RELEASE Procedure|
-- +=====================================================================+
      l_hold_source_rec        oe_holds_pvt.hold_source_rec_type;
      l_hold_release_rec       oe_holds_pvt.hold_release_rec_type;
-----------------
      l_order_number_rec       order_number_rec;
      l_order_number_rec_tab   order_number_rec_tab;
      i                        BINARY_INTEGER;
      j                        NUMBER                                := 0;
      ln_header_id             oe_order_headers_all.header_id%TYPE;
      lc_return_status         VARCHAR2 (30);
      ln_failed_count          NUMBER                                := 0;
      ln_msg_count             NUMBER;
      ln_total_fetch           NUMBER                                := 0;
      ln_sucess_count          NUMBER                                := 0;
      lc_msg_data              VARCHAR2 (2000);
      l_date_to                DATE
          := fnd_conc_date.string_to_date (p_date_to) + 1
             - 1 / (24 * 60 * 60);
      l_date_from              DATE
                                := fnd_conc_date.string_to_date (p_date_from);
      l_xx_pre_return_status   VARCHAR2 (1)                          := '';
      l_p_debug_flag           VARCHAR2 (1);
      --Added to include the logic to release holds on orders with zero dollar amount
      l_ord_total_ppf          NUMBER;
      lc_so_type               VARCHAR2 (100)                        := NULL;
      -- Added by Kmaddala as part of QC # 23068
      lc_booked_flag           VARCHAR2 (1);

      -- Added by kmaddala as part of QC # 23068

      --ln_osr_length            NUMBER                                := 0; -- Added by kmaddala as part of QC # 23068

      --Main cursor to fetch records stuck in PPF Hold status and the status of the payment,deposit,receipt and if customer is of AB type
      CURSOR c_order_number
      IS
         SELECT   *
             FROM (SELECT imp_file_name,
                                        -- TO_CHAR(H.CREATION_DATE,'dd-mon-yyyy hh24:mi:ss'),
                                        h.creation_date,
                                                        -- TO_CHAR(H.LAST_UPDATE_DATE,'dd-mon-yyyy hh24:mi:ss'),
                                                        h.last_update_date,
                          h.request_id, h.batch_id, oh.order_hold_id,
                          hs.hold_source_id, h.order_number, h.header_id,
                          hd.NAME AS hold_name, h.flow_status_code,
                          DECODE ((SELECT 1
                                     FROM oe_payments o
                                    WHERE o.header_id = h.header_id
                                      AND ROWNUM = 1),
                                  NULL, 'N',
                                  'Y'
                                 ) payment_status,
                          (SELECT DECODE
                                        (b.transaction_number,
                                         NULL, 'N',
                                         'Y'
                                        )
                             FROM xx_om_legacy_deposits a,
                                  oe_order_headers_all c,
                                  xx_om_legacy_dep_dtls b
                            WHERE b.orig_sys_document_ref(+) =
                                                       c.orig_sys_document_ref
                              AND b.transaction_number = a.transaction_number(+)
                              AND c.orig_sys_document_ref =
                                                       h.orig_sys_document_ref
                              AND h.header_id = c.header_id
                              AND ROWNUM = 1) deposit_status,
                          DECODE
                             ((SELECT 1
                                 FROM oe_payments i,
                                      ar_cash_receipts_all acra,
                                      ar_cash_receipt_history_all acrh,
                                      xx_ar_order_receipt_dtl xxar,
                                      ar_payment_schedules_all arps
                                WHERE 1 = 1
                                  AND h.header_id = i.header_id
                                  AND acra.cash_receipt_id = i.attribute15
                                  AND acrh.cash_receipt_id =
                                                          acra.cash_receipt_id
                                  AND acrh.current_record_flag = 'Y'
                                  AND xxar.cash_receipt_id =
                                                          acra.cash_receipt_id
                                  AND arps.cash_receipt_id =
                                                          acra.cash_receipt_id
                                  AND ROWNUM = 1),
                              NULL, 'N',
                              'Y'
                             ) receipt_status,
                          DECODE
                             ((SELECT 1
                                 FROM hz_customer_profiles o
                                WHERE h.sold_to_org_id = o.cust_account_id
                                  AND o.attribute3 = 'Y'
                                  AND ROWNUM = 1),
                              1, 'Y',
                              'N'
                             ) AS ab_customer
                     FROM oe_order_holds_all oh,
                          oe_order_headers_all h,
                          oe_hold_sources_all hs,
                          oe_hold_definitions hd,
                          xx_om_header_attributes_all x
                    WHERE oh.hold_source_id = hs.hold_source_id
                      AND x.header_id = h.header_id
                      AND hs.hold_id = hd.hold_id
                      AND oh.hold_release_id IS NULL
                      AND h.org_id = g_org_id
                      AND oh.header_id = h.header_id
                      AND h.flow_status_code IN ('INVOICE_HOLD', 'ENTERED')
                      -- Utsa added Entered status as part of Defect # 23068
                      AND hd.NAME = 'OD: Payment Processing Failure'
                      AND h.order_number BETWEEN NVL (p_order_number_from,
                                                      h.order_number
                                                     )
                                             AND NVL (p_order_number_to,
                                                      h.order_number
                                                     )
                      AND h.creation_date BETWEEN NVL (l_date_from,
                                                       h.creation_date
                                                      )
                                              AND NVL (l_date_to,
                                                       h.creation_date
                                                      )) stg
            WHERE 1 = 1
         ORDER BY 2;

      TYPE t_order_tab IS TABLE OF c_order_number%ROWTYPE
         INDEX BY PLS_INTEGER;

      l_order_tab              t_order_tab;
   BEGIN
      put_log_line (p_debug_flag,
                    'Y',
                    'OD: Payment Processing Failure HOLDS' || CHR (10)
                   );
      put_log_line (p_debug_flag,
                    'Y',
                       'Concurrent Program Parameters                  :::'
                    || CHR (10)
                   );
      put_log_line (p_debug_flag,
                    'Y',
                       'Order Number From                           :::'
                    || '  '
                    || p_order_number_from
                    || CHR (10)
                   );
      put_log_line (p_debug_flag,
                    'Y',
                       'Order Number To                             :::'
                    || '  '
                    || p_order_number_to
                    || CHR (10)
                   );
      put_log_line (p_debug_flag,
                    'Y',
                       'Order Date From                              :::'
                    || '  '
                    || l_date_from
                    || CHR (10)
                   );
      put_log_line (p_debug_flag,
                    'Y',
                       'Order Date To                                :::'
                    || '  '
                    || l_date_to
                    || CHR (10)
                   );
      put_log_line (p_debug_flag,
                    'Y',
                    'Release OD: Payment Processing Failure' || '  '
                    || CHR (10)
                   );
      put_log_line (p_debug_flag, 'Y', ':::BEGIN:::');

      IF p_debug_flag = 'Y'
      THEN
         put_log_line (p_debug_flag,
                       'N',
                       'Value of g_org_id is :  ' || g_org_id
                      );
      END IF;

      OPEN c_order_number;

      FETCH c_order_number
      BULK COLLECT INTO l_order_tab;

      CLOSE c_order_number;

      ln_total_fetch := l_order_tab.COUNT;
      ln_sucess_count := 0;
      put_log_line (p_debug_flag,
                    'Y',
                    'Total Fetched Orders::: ' || l_order_tab.COUNT
                   );

      IF (l_order_tab.COUNT > 0)
      THEN
         FOR i IN l_order_tab.FIRST .. l_order_tab.LAST
         LOOP
            BEGIN
               -- Begin / Exception part  included as part of Qc # 23068 by Kmaddala
               l_order_number_rec := NULL;
               l_order_number_rec.imp_file_name :=
                                                l_order_tab (i).imp_file_name;
               l_order_number_rec.creation_date :=
                                                l_order_tab (i).creation_date;
               l_order_number_rec.last_update_date :=
                                             l_order_tab (i).last_update_date;
               l_order_number_rec.request_id := l_order_tab (i).request_id;
               l_order_number_rec.batch_id := l_order_tab (i).batch_id;
               l_order_number_rec.order_hold_id :=
                                                l_order_tab (i).order_hold_id;
               l_order_number_rec.hold_source_id :=
                                               l_order_tab (i).hold_source_id;
               l_order_number_rec.order_number :=
                                                 l_order_tab (i).order_number;
               l_order_number_rec.header_id := l_order_tab (i).header_id;
               l_order_number_rec.hold_name := l_order_tab (i).hold_name;
               l_order_number_rec.flow_status_code :=
                                             l_order_tab (i).flow_status_code;
               l_order_number_rec.payment_status :=
                                               l_order_tab (i).payment_status;
               l_order_number_rec.deposit_status :=
                                               l_order_tab (i).deposit_status;
               l_order_number_rec.ab_customer := l_order_tab (i).ab_customer;
               l_order_number_rec.receipt_status :=
                                               l_order_tab (i).receipt_status;
               l_order_number_rec_tab (j) := l_order_number_rec;

               IF p_debug_flag = 'Y'
               THEN
                  put_log_line (p_debug_flag, 'N', ' ');
                  put_log_line (p_debug_flag,
                                'N',
                                   'Sales Order Number is :::'
                                || l_order_tab (i).order_number
                               );
                  put_log_line (p_debug_flag, 'N', ' ');
               END IF;

               --part 2
               -- Now Remove the hold on the order
               l_hold_source_rec.hold_source_id :=
                                                l_order_tab (i).hold_source_id;
               l_hold_source_rec.hold_id := l_order_tab (i).order_hold_id;
               l_hold_release_rec.release_reason_code :=
                                                  'MANUAL_RELEASE_MARGIN_HOLD';
               l_hold_release_rec.release_comment := 'Post Production Cleanup';
               l_hold_release_rec.hold_source_id :=
                                                l_order_tab (i).hold_source_id;
               l_hold_release_rec.order_hold_id :=
                                                 l_order_tab (i).order_hold_id;

               IF p_debug_flag = 'Y'
               THEN
                  put_log_line (p_debug_flag, 'N', ' ');
                  put_log_line (p_debug_flag,
                                'N',
                                   'HEADER_ID      : '
                                || l_order_tab (i).header_id
                               );
                  put_log_line (p_debug_flag,
                                'N',
                                   'HOLD_SOURCE_ID : '
                                || l_order_tab (i).hold_source_id
                               );
                  put_log_line (p_debug_flag,
                                'N',
                                   'HOLD_ID        : '
                                || l_order_tab (i).order_hold_id
                               );
                  put_log_line (p_debug_flag, 'N', ' ');
               END IF;

               --Logic to segregate the records which will be called by Create Receipt Procedure
               --before OD: Payment Processing Failure Hold is being released

               --PPF Holds on all AB Customer Orders should be released without further check
               IF (l_order_tab (i).ab_customer = 'Y')
               THEN
                  IF p_debug_flag = 'Y'
                  THEN
                     put_log_line (p_debug_flag, 'N', ' ');
                     put_log_line (p_debug_flag,
                                   'N',
                                   'PPF Holds on  AB Customers Orders'
                                  );
                     put_log_line (p_debug_flag,
                                   'N',
                                   'Calling the Release Hold on the order'
                                  );
                     put_log_line (p_debug_flag, 'N', ' ');
                  END IF;

                  GOTO release_hold_api;
               --PPF Holds on non AB Customer Orders should be verified on the basis of the Receipt and Payment Information
               ELSE
                  --If both Payment and Receipt Status is Y
                  IF (    l_order_tab (i).receipt_status = 'Y'
                      AND l_order_tab (i).payment_status = 'Y'
                     )
                  THEN
                     IF p_debug_flag = 'Y'
                     THEN
                        put_log_line (p_debug_flag, 'N', ' ');
                        put_log_line
                           (p_debug_flag,
                            'N',
                            'PPF Holds on non AB Customers Orders are further checked on the Payment and Receipt Status'
                           );
                        put_log_line (p_debug_flag,
                                      'N',
                                         'Payment Status :  '
                                      || l_order_tab (i).payment_status
                                      || '   and  Receipt Status : '
                                      || l_order_tab (i).receipt_status
                                     );
                        put_log_line (p_debug_flag,
                                      'N',
                                      'Calling the Release Hold on the order'
                                     );
                        put_log_line (p_debug_flag, 'N', ' ');
                     END IF;

                     GOTO release_hold_api;
                  ELSIF (    l_order_tab (i).receipt_status = 'N'
                         AND l_order_tab (i).payment_status = 'Y'
                        )
                  THEN
                     IF p_debug_flag = 'Y'
                     THEN
                        put_log_line (p_debug_flag, 'N', ' ');
                        put_log_line (p_debug_flag,
                                      'N',
                                         'Payment Status :  '
                                      || l_order_tab (i).payment_status
                                      || '   and  Receipt Status : '
                                      || l_order_tab (i).receipt_status
                                     );
                        put_log_line
                           (p_debug_flag,
                            'N',
                            'Receipt needs to be created before releasing Hold on the order'
                           );
                        put_log_line (p_debug_flag, 'N', ' ');
                     END IF;

                     --Debug Messages before calling the procedure
                     IF p_debug_flag = 'Y'
                     THEN
                        put_log_line (p_debug_flag, 'N', ' ');
                        put_log_line (p_debug_flag,
                                      'N',
                                         'Passing the HEADER_ID      : '
                                      || l_order_tab (i).header_id
                                     );
                        put_log_line
                           (p_debug_flag,
                            'N',
                               'Calling XX_CREATE_PREPAY_RECEIPT package for the Order :  '
                            || l_order_tab (i).order_number
                           );
                        put_log_line (p_debug_flag, 'N', ' ');
                     END IF;

                     --Calling Create Receipt Procedure
                     l_p_debug_flag := p_debug_flag;

                     --xx_create_prepay_receipt
                     -- Code Change started -- by kmaddala as part of Defect 23068

                     -------------------
-- BEGIN
                     SELECT ot.NAME
                       INTO lc_so_type
                       FROM oe_order_headers_all h,
                            oe_order_lines_all l,
                            oe_transaction_types_tl ot
                      WHERE 1 = 1
                        AND h.header_id = l.header_id
                        AND l.line_type_id = ot.transaction_type_id
                        AND h.header_id = l_order_tab (i).header_id
                        AND ot.NAME IN
                               ('OD CA POS STANDARD - LINE',
                                'OD US POS STANDARD - LINE',
                                'OD CA STANDARD - LINE',
                                'OD US STANDARD - LINE'
                               )
                        AND ROWNUM = 1;

                     IF p_debug_flag = 'Y'
                     THEN
                        put_log_line (p_debug_flag,
                                      'N',
                                      'Sales Order Type :  ' || lc_so_type
                                     );
                     END IF;

                     -- Chekcing If the Sales Order is AOPS  or not.
                     IF (   lc_so_type = 'OD CA STANDARD - LINE'
                         OR lc_so_type = 'OD US STANDARD - LINE'
                        )
                     THEN
--------------------
                        xx_ar_prepay_receipt_pkg.xx_ar_prepay_receipt_proc
                                   (p_header_id          => l_order_tab (i).header_id,
                                    -- p_debug_flag         => l_p_debug_flag,
                                    p_return_status      => l_xx_pre_return_status
                                   );

                        -- Code change ended by kmaddala as part of QC # 23068
                        IF p_debug_flag = 'Y'
                        THEN
                           put_log_line (p_debug_flag, 'N', ' ');
                           put_log_line
                                  (p_debug_flag,
                                   'N',
                                      'Return from XX_CREATE_PREPAY_RECEIPT '
                                   || CHR (10)
                                  );
                           put_log_line (p_debug_flag, 'N', ' ');
                        END IF;

                        --Check if the return status of the procedure.
                        IF (l_xx_pre_return_status = 'S')
                        THEN
                           IF p_debug_flag = 'Y'
                           THEN
                              put_log_line (p_debug_flag, 'N', ' ');
                              put_log_line
                                     (p_debug_flag,
                                      'N',
                                      'Calling the Release Hold on the order'
                                     );
                              put_log_line (p_debug_flag, 'N', ' ');
                           END IF;

                           GOTO release_hold_api;
                        ELSE
                           IF p_debug_flag = 'Y'
                           THEN
                              put_log_line (p_debug_flag, 'N', ' ');
                              put_log_line
                                 (p_debug_flag,
                                  'N',
                                     'XX_CREATE_PREPAY_RECEIPT has failed to create a receipt   : '
                                  || l_order_tab (i).order_number
                                 );
                              put_log_line
                                 (p_debug_flag,
                                  'N',
                                  'Hold will not be released against the order'
                                 );
                              put_log_line (p_debug_flag, 'N', ' ');
                           END IF;

                           GOTO ppf_hold_not_to_be_released;
                        END IF;
                     END IF;        -- Added by kmaddala as part of QC # 23068
------------------------------------------
                  ELSIF (    l_order_tab (i).receipt_status = 'N'
                         AND l_order_tab (i).payment_status = 'N'
                        )
                  THEN
                     BEGIN
                        SELECT order_total
                          INTO l_ord_total_ppf
                          FROM xx_om_header_attributes_all
                         WHERE header_id = l_order_tab (i).header_id;
                     EXCEPTION
                        WHEN NO_DATA_FOUND
                        THEN
                           fnd_file.put_line (fnd_file.LOG,
                                              ' No Data Found To Process'
                                             );
                        WHEN OTHERS
                        THEN
                           fnd_file.put_line
                                    (fnd_file.LOG,
                                     ' Exception happened at L_ORD_TOTAL_PPF'
                                    );
                     END;

                     IF (l_ord_total_ppf = 0)
                     THEN
                        IF p_debug_flag = 'Y'
                        THEN
                           put_log_line (p_debug_flag, 'N', ' ');
                           put_log_line (p_debug_flag,
                                         'N',
                                            'L_ORD_TOTAL_PPF is  : '
                                         || l_ord_total_ppf
                                        );
                           put_log_line
                              (p_debug_flag,
                               'N',
                               'This is a zero dollar transaction, so Hold should be released'
                              );
                           put_log_line (p_debug_flag,
                                         'N',
                                         'Calling Hold Release Program '
                                        );
                        END IF;

                        GOTO release_hold_api;
                     ELSE
                        IF p_debug_flag = 'Y'
                        THEN
                           put_log_line (p_debug_flag, 'N', ' ');
                           put_log_line
                              (p_debug_flag,
                               'N',
                                  'The order is not elligible for PPF Hold release '
                               || l_order_tab (i).order_number
                              );
                           put_log_line (p_debug_flag, 'N', ' ');
                        END IF;

                        GOTO ppf_hold_not_to_be_released;
                     END IF;
-------------------------------------------------------
                  ELSE
                     IF p_debug_flag = 'Y'
                     THEN
                        put_log_line (p_debug_flag, 'N', ' ');
                        put_log_line (p_debug_flag,
                                      'N',
                                         'If the Payment Staus is '
                                      || l_order_tab (i).payment_status
                                      || '  and Receip Status is  '
                                      || l_order_tab (i).receipt_status
                                      || ' for Non AB
Customers '
                                     );
                        put_log_line
                           (p_debug_flag,
                            'N',
                               'The order is not elligible for PPF Hold release '
                            || l_order_tab (i).order_number
                           );
                        put_log_line (p_debug_flag, 'N', ' ');
                     END IF;

                     GOTO ppf_hold_not_to_be_released;
                  END IF;
               END IF;

               --Type 2
               <<release_hold_api>>
               oe_holds_pub.release_holds
                                    (p_hold_source_rec       => l_hold_source_rec,
                                     p_hold_release_rec      => l_hold_release_rec,
                                     x_return_status         => lc_return_status,
                                     x_msg_count             => ln_msg_count,
                                     x_msg_data              => lc_msg_data
                                    );

                          --End of Type 2
--end of part 12
               IF p_debug_flag = 'Y'
               THEN
                  put_log_line (p_debug_flag, 'N', ' ');
                  put_log_line (p_debug_flag,
                                'N',
                                'Hold Return Status::' || lc_return_status
                               );
                  put_log_line (p_debug_flag, 'N', ' ');
               END IF;

               IF lc_return_status = fnd_api.g_ret_sts_success
               THEN
                  IF p_debug_flag = 'Y'
                  THEN
                     put_log_line (p_debug_flag, 'N', ' ');
                     put_log_line (p_debug_flag, 'N', 'Holds API Success');
                     put_log_line (p_debug_flag, 'N', ' ');
                  END IF;

                  COMMIT;

                  -- Code change Started--added by Kmaddala as part of QC # 23068
                  SELECT h.booked_flag
                    INTO lc_booked_flag
                    FROM oe_order_headers_all h
                   WHERE 1 = 1 AND h.header_id = l_order_tab (i).header_id;

                  IF lc_booked_flag = 'Y'
                  THEN
                     -- Code change Ended--added by Kmaddala as part of QC # 23068
                     wf_engine.completeactivityinternalname
                               (itemtype      => 'OEOH',
                                itemkey       => l_order_tab (i).header_id,
                                activity      => 'HDR_INVOICE_INTERFACE_ELIGIBLE',
                                RESULT        => NULL
                               );
                  -- Code change Started--added by Kmaddala as part of QC # 23068
                  ELSE
                     wf_engine.completeactivityinternalname
                                        (itemtype      => 'OEOH',
                                         itemkey       => l_order_tab (i).header_id,
                                         activity      => 'BOOK_ELIGIBLE',
                                         RESULT        => NULL
                                        );
                  END IF;

                  -- Code change Ended--added by Kmaddala as part of QC # 23068
                  ln_sucess_count := ln_sucess_count + 1;
                  COMMIT;
               ELSIF lc_return_status IS NULL
               THEN
                  IF p_debug_flag = 'Y'
                  THEN
                     put_log_line (p_debug_flag, 'N', ' ');
                     put_log_line (p_debug_flag,
                                   'N',
                                   'Status is null from Holds API '
                                  );
                     put_log_line (p_debug_flag, 'N', ' ');
                  END IF;
               ELSE
                  IF p_debug_flag = 'Y'
                  THEN
                     put_log_line (p_debug_flag, 'N', ' ');
                     put_log_line (p_debug_flag,
                                   'N',
                                   'Holds API Failed: ' || lc_msg_data
                                  );
                     put_log_line (p_debug_flag, 'N', ' ');
                  END IF;

                  FOR i IN 1 .. oe_msg_pub.count_msg
                  LOOP
                     lc_msg_data :=
                          oe_msg_pub.get (p_msg_index      => i,
                                          p_encoded        => 'F');

                     IF p_debug_flag = 'Y'
                     THEN
                        put_log_line (p_debug_flag, 'N', ' ');
                        put_log_line (p_debug_flag,
                                      'N',
                                      i || ') ' || lc_msg_data
                                     );
                        put_log_line (p_debug_flag, 'N', ' ');
                     END IF;
                  END LOOP;

                  ROLLBACK;
               END IF;

               <<ppf_hold_not_to_be_released>>
               j := j + 1;
            -- Below Exception part has been included inside the loop as part of QC # 23068 by Kmaddala
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  put_log_line
                             (p_debug_flag,
                              'Y',
                              'Inside of Loop -  No Data Found To Process:::'
                             );
               WHEN OTHERS
               THEN
                  put_log_line (p_debug_flag,
                                'Y',
                                   'Inside the loop - When Others Raised: '
                                || SQLERRM
                               );
            END;
         -- Exception Part ended as part of 23068 - by Kmaddala
         END LOOP;

         IF p_debug_flag = 'Y'
         THEN
            put_log_line (p_debug_flag, 'N', ' ');
            put_log_line (p_debug_flag, 'N', ' :::End of Program:::');
            put_log_line (p_debug_flag, 'N', ' ');
         END IF;
      ELSE
         IF p_debug_flag = 'Y'
         THEN
            put_log_line (p_debug_flag, 'N', ' ');
            put_log_line (p_debug_flag,
                          'N',
                          ' No record in Payment Processing Failure Hold'
                         );
            put_log_line (p_debug_flag, 'N', ' ');
         END IF;
      END IF;

      IF p_debug_flag = 'Y'
      THEN
         put_log_line (p_debug_flag, 'N', ' ');
         put_log_line (p_debug_flag,
                       'N',
                          ' Sucessfully processed order Count:::'
                       || ln_sucess_count
                      );
         put_log_line (p_debug_flag,
                       'N',
                       ' Failed to process order Count:::' || ln_failed_count
                      );
         put_log_line (p_debug_flag, 'N', ' ');
      END IF;

      ln_failed_count := ln_total_fetch - ln_sucess_count;
      put_log_line ('N', 'N', ' :::End of Program:::');
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         put_log_line (p_debug_flag, 'Y', ' No Data Found To Process:::');
      WHEN OTHERS
      THEN
         put_log_line (p_debug_flag, 'Y', ' When Others Raised: ' || SQLERRM);
   END;
END xx_om_releasehold;
/
SHOW ERRORS;
EXIT;