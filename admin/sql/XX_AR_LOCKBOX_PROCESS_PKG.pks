create or replace
PACKAGE      XX_AR_LOCKBOX_PROCESS_PKG AS
-- +=================================================================================+
-- |                       Office Depot - Project Simplify                           |
-- |                            Providge Consulting                                  |
-- +=================================================================================+
-- | Name       : xx_ar_lockbox_process_pkg.pks                                      |
-- | Description: AR Lockbox Custom Auto Cash Rules E0062-Extension                  |
-- |                                                                                 |
-- |                                                                                 |
-- |                                                                                 |
-- |                                                                                 |
-- |Change Record                                                                    |
-- |==============                                                                   |
-- |Version   Date         Authors            Remarks                                |
-- |========  ===========  ===============    ============================           |
-- |DRAFT 1A  07-AUG-2007  Shiva Rao/SunayanM Initial draft version                  |
-- |      1.1 22-OCT-2009  RamyaPriya M       Modified for the CR #684 --            |
-- |                                          (Defect #976,#1614,#1858)              |
-- |      1.3 02-FEB-2010  RamyaPriya M       Modified for the Defect #3983,3984     |
-- |      1.4 12-FEB-2010  RamyaPriya M       Modified for the Defect #3983          |
-- |      1.5 09-APR-2010  RamyaPriya M       Modified for the Defect #4320          |
-- |      1.6 16-JAN-2012  P.Sankaran         Default of 5 for backorder defect#     |
-- |                                          16200                                  |
-- +=================================================================================+
-- | Name        : LOCKBOX_PROCESS_MAIN                                              |
-- | Description : This procedure will be used to load and process the               |
-- |               AR Lockbox Custom Auto Cash Rules                                 |
-- |                                                                                 |
-- | Parameters  : p_filename                                                        |
-- |               p_email_notf                                                      |
-- |               p_check_digit                                                     |
-- |                                                                                 |
-- | Returns     : x_errbuf                                                          |
-- |               x_retcode                                                         |
-- +=================================================================================+
PROCEDURE lockbox_process_main( x_errbuf                  OUT     NOCOPY     VARCHAR2
                               ,x_retcode                 OUT     NOCOPY     NUMBER
                               ,p_filename                IN                 VARCHAR2
                               ,p_email_notf              IN                 VARCHAR2  DEFAULT NULL
                               ,p_check_digit             IN                 NUMBER
                               ,p_trx_type                IN                 VARCHAR2  DEFAULT NULL
                               ,p_trx_threshold           IN                 NUMBER    DEFAULT NULL
                               ,p_from_days               IN                 NUMBER    DEFAULT NULL
                               ,p_to_days                 IN                 NUMBER    DEFAULT NULL
                               --,p_days_start_purge        IN                 NUMBER    DEFAULT 120  --Commented for the Defect #4320
                               ,p_debug_flag              IN                 VARCHAR2  DEFAULT 'Y'
                               ,p_back_order_configurable IN                 NUMBER    DEFAULT 5  --Added for Defect #3893 on 26-JAN-10  -- Added default Defect # 16200
                               );

-- +=================================================================================+
-- | Name        : CUSTOM_AUTO_CASH                                                  |
-- | Description : This procedure will be used to process the                        |
-- |               AR Lockbox Custom Auto Cash Rules                                 |
-- |                                                                                 |
-- | Parameters  : p_process_num                                                     |
-- |               p_check_digit                                                     |
-- |                                                                                 |
-- | Returns     : x_errmsg                                                          |
-- |               x_retstatus                                                       |
-- +=================================================================================+
PROCEDURE  custom_auto_cash     (x_errmsg                  OUT   NOCOPY  VARCHAR2
                                ,x_retstatus               OUT   NOCOPY  NUMBER
                                ,p_process_num             IN            VARCHAR2
                                ,p_check_digit             IN            NUMBER
                                ,p_trx_type                IN            VARCHAR2  DEFAULT NULL
                                ,p_trx_threshold           IN            NUMBER    DEFAULT NULL
                                ,p_from_days               IN            NUMBER    DEFAULT NULL
                                ,p_to_days                 IN            NUMBER    DEFAULT NULL
                                ,p_back_order_configurable IN            NUMBER    --Added for Defect #3893 on 26-JAN-10
                                );

-- +=================================================================================+
-- | Name        : VALID_CUSTOMER                                                    |
-- | Description : This functions will be used to validate the customer              |
-- |               this fucntion called form AR Lockbox Custom Auto Cash Rules       |
-- |                                                                                 |
-- | Parameters  : p_transit_routing_num                                             |
-- |               p_account                                                         |
-- |                                                                                 |
-- | Returns     : NUMBER (Customer Id)                                              |
-- +=================================================================================+
-- Decalre Function Check for Valid Customer
/*FUNCTION valid_customer      (p_transit_routing_num      IN            VARCHAR2
                             ,p_account                  IN            VARCHAR2
                             )RETURN NUMBER ;*/ --Commented for the CR#684 --Defect #976

-- |          Added for the CR#684 --Defect #976                                     |
-- +=================================================================================+
-- | Name        : VALID_CUSTOMER                                                    |
-- | Description : This procedure will be used to validate the customer              |
-- |               this procedure called from AR Lockbox Custom Auto Cash Rules      |
-- |                                                                                 |
-- | Parameters  : p_transit_routing_num                                             |
-- |               p_account                                                         |
-- |                                                                                 |
-- | Returns     : x_customer_id                                                     |
-- |               x_party_id                                                        |
-- |               x_micr_cust_num                                                   |
-- +=================================================================================+
PROCEDURE  valid_customer (x_customer_id             OUT   NOCOPY   NUMBER
                          ,x_party_id                OUT   NOCOPY   NUMBER
                          ,x_micr_cust_num           OUT   NOCOPY   VARCHAR2
                          ,p_transit_routing_num      IN            VARCHAR2
                          ,p_account                  IN            VARCHAR2
                          );
-- +=================================================================================+
-- | Name        : CHECK_POSITION_MATCH                                              |
-- | Description : This functions will be used to match the Oracle Invoice and Custom|
-- |               Invoice,this fucntion called form AR Lockbox Custom Auto Cash Rules|
-- |                                                                                 |
-- | Parameters  : p_oracle_invoice                                                  |
-- |               p_custom_invoice                                                  |
-- |               p_profile_digit_check                                             |
-- |                                                                                 |
-- | Returns     : BOOLEAN (Match = TRUE / Not Match = FALSE)                        |
-- +=================================================================================+
-- Decalre Function Check Invoice Position Match
FUNCTION check_position_match(p_oracle_invoice           IN            VARCHAR2
                             ,p_custom_invoice           IN            VARCHAR2
                             ,p_profile_digit_check      IN            NUMBER
                             )RETURN BOOLEAN;

-- +=================================================================================+
-- | Name        : DISCOUNT_CALCULATE                                                |
-- | Description : This functions will be used to Get The Discount Percentage should |
-- |               apply for this customer and invoice,this fucntion called form     |
-- |               AR Lockbox Custom Auto Cash Rules                                 |
-- |                                                                                 |
-- | Parameters  : p_payment_term_id                                                 |
-- |              ,p_trx_date         --Added for Defect #3984                       |
-- |              ,p_deposit_date     --Added for Defect #3984                       |
-- |                                                                                 |
-- | Returns     : NUMBER (Discount % )                                              |
-- +=================================================================================+
-- Decalre Function Check Discount Percentage from customer profile
FUNCTION discount_calculate  (p_payment_term_id          IN  NUMBER
                             ,p_trx_date                 IN  DATE   --Added for Defect #3984
                             ,p_deposit_date             IN  DATE   --Added for Defect #3984
                            -- ,p_paymentr_diff_days     IN  NUMBER --Commented for Defect #3984
                             )RETURN NUMBER ;

-- +=================================================================================+
-- | Name        : DATE_RANGE_RULE                                                   |
-- | Description : This Procedure will be used to match the sum of all invoices for a|
-- |               specific date range bucket,this fucntion called form              |
-- |               AR Lockbox Custom Auto Cash Rules                                 |
-- |                                                                                 |
-- | Parameters  : p_customer_id                                                     |
-- |               p_match_type                                                      |
-- |               p_record                                                          |
-- |               p_term_id                                                         |
-- |               p_deposit_date                                                    |
-- |               p_cur_precision                                                   |
-- |                                                                                 |
-- | Returns     : x_errmsg                                                          |
-- |               x_retstatus                                                       |
-- +=================================================================================+
-- Declare Procedure for Custom Auto Cash Date Range Rule
PROCEDURE date_range_rule     (x_errmsg                  OUT   NOCOPY  VARCHAR2
                              ,x_retstatus               OUT   NOCOPY  NUMBER
                              ,x_date_range_match        OUT   NOCOPY  VARCHAR2
                              ,p_customer_id             IN            NUMBER
                              ,p_match_type              IN            VARCHAR2  DEFAULT NULL
                              ,p_record                  IN            xx_ar_payments_interface%ROWTYPE
                              ,p_term_id                 IN            NUMBER    DEFAULT NULL
                              ,p_deposit_date            IN            DATE      DEFAULT NULL
                              ,p_cur_precision           IN            NUMBER    DEFAULT NULL
                              ,p_process_num             IN            VARCHAR2
                              ,p_rowid                   IN            VARCHAR2
                             );

-- +=================================================================================+
-- | Name        : PULSE_PAY_RULE                                                    |
-- | Description : This Procedure will be used to match the sum of all invoices for a|
-- |               unique date for last 3 months,this fucntion called form           |
-- |               AR Lockbox Custom Auto Cash Rules                                 |
-- |                                                                                 |
-- | Parameters  : p_customer_id                                                     |
-- |               p_match_type                                                      |
-- |               p_record                                                          |
-- |               p_term_id                                                         |
-- |               p_deposit_date                                                    |
-- |               p_cur_precision                                                   |
-- |                                                                                 |
-- | Returns     : x_errmsg                                                          |
-- |               x_retstatus                                                       |
-- +=================================================================================+
-- Declare Procedure for Custom Auto Cash Pulse Pay Rule
PROCEDURE pulse_pay_rule      (x_errmsg                  OUT   NOCOPY  VARCHAR2
                              ,x_retstatus               OUT   NOCOPY  NUMBER
                              ,x_pulse_pay_match         OUT   NOCOPY  VARCHAR2
                              ,p_customer_id             IN            NUMBER
                              ,p_match_type              IN            VARCHAR2  DEFAULT NULL
                              ,p_record                  IN            xx_ar_payments_interface%ROWTYPE
                              ,p_term_id                 IN            NUMBER    DEFAULT NULL
                              ,p_deposit_date            IN            DATE      DEFAULT NULL
                              ,p_cur_precision           IN            NUMBER    DEFAULT NULL
                              ,p_process_num             IN            VARCHAR2
                              ,p_rowid                   IN            VARCHAR2
                              );
-- +=================================================================================+
-- | Name        : ANY_COMBO                                                         |
-- | Description : This procedure will be used Find out any combination invoice match|
-- |                                                                                 |
-- |                                                                                 |
-- | Parameters  : p_customer_id                                                     |
-- |               p_match_type                                                      |
-- |               p_term_id                                                         |
-- |               p_deposit_date                                                    |
-- |               p_cur_precision                                                   |
-- |               p_process_num                                                     |
-- |               p_rowid                                                           |
-- |               p_record                                                          |
-- | Returns     : x_errmsg                                                          |
-- |               x_retstatus                                                       |
-- |               x_any_combo_match                                                 |
-- +=================================================================================+
PROCEDURE any_combo       ( x_errmsg          OUT NOCOPY   VARCHAR2
                           ,x_retstatus       OUT NOCOPY   NUMBER
                           ,x_any_combo_match OUT NOCOPY   VARCHAR2
                           ,p_customer_id     IN           NUMBER
                           ,p_match_type      IN           VARCHAR2 DEFAULT NULL
                           ,p_record          IN           xx_ar_payments_interface%ROWTYPE
                           ,p_process_num     IN           VARCHAR2
                           ,p_rowid           IN           VARCHAR2
                           ,p_max_trx         IN           NUMBER
                           ,p_from_days       IN           NUMBER
                           ,p_to_days         IN           NUMBER
                           ,p_trx_class       IN           VARCHAR2
                           ,p_term_id         IN           NUMBER    DEFAULT NULL
                           ,p_deposit_date    IN           DATE      DEFAULT NULL
                           ,p_cur_precision   IN           NUMBER    DEFAULT NULL
                          );

-- +=================================================================================+
-- | Name        : CONSOLIDATED_BILL_RULE                                            |
-- | Description : This procedure will apply Consolidated Bill Rulw for all the '6'  |
-- |               record type records after not qulify exact match, clear account   |
-- |               match and partial invoice match process                           |
-- |                                                                                 |
-- | Parameters  : p_record                                                          |
-- |               p_term_id                                                         |
-- |               p_customer_id                                                     |
-- |               p_deposit_date                                                    |
-- |               p_rowid                                                           |
-- |               p_process_num                                                     |
-- |                                                                                 |
-- | Returns     : x_errmsg                                                          |
-- |               x_retstatus                                                       |
-- |                                                                                 |
-- +=================================================================================+
-- Declare Procedure for Consolidated Bill Rule
PROCEDURE  consolidated_bill_rule(x_errmsg             OUT   NOCOPY  VARCHAR2
                                 ,x_retstatus          OUT   NOCOPY  NUMBER
                                 ,p_record             IN            xx_ar_payments_interface%ROWTYPE
                                 ,p_term_id            IN            NUMBER
                                 ,p_customer_id        IN            NUMBER
                                 ,p_deposit_date       IN            DATE
                                 ,p_rowid              IN            VARCHAR2
                                 ,p_process_num        IN            VARCHAR2
                                 );
-- +=================================================================================+
-- | Name        : AS_IS_CONSOLIDATED_MATCH_RULE       -- Added for Defect #3983     |
-- | Description : 1. Validate BAI Invoice Number is a Consolidated Bill Number      |
-- |               2. If Match Found then delete current '4' records                 |
-- |                  and create '4' records using the individual invoices/CMs that  |
-- |                  are open for that consolidated bill                            |
-- |               3. If Match not found then proceed with Partial Invoice Match     |
-- |                                                                                 |
-- |                                                                                 |
-- | Parameters  : p_record                                                          |
-- |               p_term_id                                                         |
-- |               p_customer_id                                                     |
-- |               p_deposit_date                                                    |
-- |               p_rowid                                                           |
-- |               p_process_num                                                     |
-- |               p_invoice_num                                                     |
-- |                                                                                 |
-- | Returns     : x_errmsg                                                          |
-- |               x_retstatus                                                       |
-- |               x_invoice_exists                                                  |
-- |               x_invoice_status                                                  |
-- |                                                                                 |
-- +=================================================================================+
PROCEDURE as_is_consolidated_match_rule(x_errmsg             OUT   NOCOPY  VARCHAR2
                                       ,x_retstatus          OUT   NOCOPY  NUMBER
                                       ,x_invoice_exists     OUT   NOCOPY  VARCHAR2
                                       ,x_invoice_status     OUT   NOCOPY  VARCHAR2
                                       ,p_record             IN            xx_ar_payments_interface%ROWTYPE
                                       ,p_term_id            IN            NUMBER
                                       ,p_customer_id        IN            NUMBER
                                       ,p_deposit_date       IN            DATE
                                       ,p_rowid              IN            VARCHAR2
                                       ,p_process_num        IN            VARCHAR2
                                       ,p_invoice_num        IN            NUMBER
                                       ,p_applied_amt        IN            NUMBER       --Added for Defect #3983 on 12-FEB-10
                                         );
-- +=================================================================================+
-- | Name        : AUTO_CASH_MATCH_RULES                                             |
-- | Description : This procedure will apply Date Range / Pulse Pay /                |
-- |               Any Combination Rules for all the '6' record type records         |
-- |               after not qulify exact match, clear account match,                |
-- |               and consolidated bill rule match partial invoice match process    |
-- |                                                                                 |
-- | Parameters  : p_record                                                          |
-- |               p_term_id                                                         |
-- |               p_customer_id                                                     |
-- |               p_deposit_date                                                    |
-- |               p_rowid                                                           |
-- |               p_process_num                                                     |
-- |                                                                                 |
-- | Returns     : x_errmsg                                                          |
-- |               x_retstatus                                                       |
-- |                                                                                 |
-- +=================================================================================+
-- Declare Procedure for Custom Auto Cash Auto Cash Match Rules
PROCEDURE  auto_cash_match_rules(x_errmsg             OUT   NOCOPY  VARCHAR2
                                ,x_retstatus          OUT   NOCOPY  NUMBER
                                ,p_record             IN            xx_ar_payments_interface%ROWTYPE
                                ,p_term_id            IN            NUMBER
                                ,p_customer_id        IN            NUMBER
                                ,p_deposit_date       IN            DATE
                                ,p_rowid              IN            VARCHAR2
                                ,p_process_num        IN            VARCHAR2
                                ,p_trx_type           IN            VARCHAR2  DEFAULT NULL
                                ,p_trx_threshold      IN            NUMBER    DEFAULT NULL
                                ,p_from_days          IN            NUMBER    DEFAULT NULL
                                ,p_to_days            IN            NUMBER    DEFAULT NULL
                                );

-- +=================================================================================+
-- | Name        : CREATE_INTERFACE_RECORD                                           |
-- | Description : This procedure will be created the records into                   |
-- |               xx_ar_payments_interface table for record type 4                  |
-- |                                                                                 |
-- | Parameters  : p_record                                                          |
-- |                                                                                 |
-- |                                                                                 |
-- | Returns     : x_errmsg                                                          |
-- |               x_retstatus                                                       |
-- |                                                                                 |
-- +=================================================================================+
-- Declare Procedure for Custom Auto Cash create interface record
PROCEDURE create_interface_record(x_errmsg               OUT    NOCOPY  VARCHAR2
                                 ,x_retstatus            OUT    NOCOPY  NUMBER
                                 ,p_record               IN             xx_ar_payments_interface%ROWTYPE
                                 );

-- +=================================================================================+
-- | Name        : UPDATE_LCKB_REC                                                   |
-- | Description : This procedure will be used for update the status in custom       |
-- |               auto lock box interface table xx_ar_payments_interface            |
-- |                                                                                 |
-- | Parameters  : p_process_num                                                     |
-- |               p_record_type                                                     |
-- |               p_invoice                                                         |
-- |               p_inv_match_status                                                |
-- |               p_invoice1_2_3                                                    |
-- |               p_invoice1_2_3_status                                             |
-- |               p_match_type                                                      |
-- |               p_rowid                                                           |
-- |                                                                                 |
-- | Returns     : x_errmsg                                                          |
-- |               x_retstatus                                                       |
-- |                                                                                 |
-- +=================================================================================+
-- Declare Procedure for Custom Auto Cash update interface record
PROCEDURE update_lckb_rec ( x_errmsg                     OUT    NOCOPY  VARCHAR2
                          , x_retstatus                  OUT    NOCOPY  NUMBER
                          , p_process_num                IN             VARCHAR2
                          , p_record_type                IN             VARCHAR2
                          , p_invoice                    IN             VARCHAR2   DEFAULT NULL
                          , p_inv_match_status           IN             VARCHAR2   DEFAULT NULL
                          , p_invoice1_2_3               IN             VARCHAR2   DEFAULT NULL
                          , p_invoice1_2_3_status        IN             VARCHAR2   DEFAULT NULL
                          , p_match_type                 IN             VARCHAR2   DEFAULT NULL
                          , p_rowid                      IN             VARCHAR2
                          );

-- +=================================================================================+
-- | Name        : DELETE_LCKB_REC                                                   |
-- | Description : This procedure will be used for delete the record type 4 records  |
-- |               from custom interface table if any custom auto cash rule or       |
-- |               Consolidated Bill Rule will match                                 |
-- | Parameters  : p_process_num                                                     |
-- |               p_record_type                                                     |
-- |               p_rowid                                                           |
-- |               p_customer_id                                                     |
-- |               p_record                                                          |
-- |                                                                                 |
-- | Returns     : x_errmsg                                                          |
-- |               x_retstatus                                                       |
-- |                                                                                 |
-- +=================================================================================+
PROCEDURE delete_lckb_rec ( x_errmsg                    OUT   NOCOPY  VARCHAR2
                          , x_retstatus                 OUT   NOCOPY  NUMBER
                          , p_process_num               IN            VARCHAR2
                          , p_record_type               IN            VARCHAR2
                          , p_rowid                     IN            VARCHAR2
                          , p_customer_id               IN            NUMBER
                          , p_record                    IN            xx_ar_payments_interface%ROWTYPE
                          );

lt_related_custid_type XX_AR_CUSTID_TAB_T := XX_AR_CUSTID_TAB_T();   -- Added for the CR #684 -- Defect #976

END XX_AR_LOCKBOX_PROCESS_PKG ;
/