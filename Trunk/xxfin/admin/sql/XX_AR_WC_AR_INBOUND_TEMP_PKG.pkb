create or replace
PACKAGE BODY XX_AR_WC_AR_INBOUND_TEMP_PKG AS
-- +====================================================================+
-- |                  Office Depot - Project Simplify                   |
-- |                  Office Depot                                      |
-- +====================================================================+
-- | Name  : XX_AR_WC_AR_INBOUND_TEMP_PKG                                    |
-- | Rice ID : I2161                                                    |
-- | Description  : This package contains procedures related to the     |
-- | Web collect data to be processed in EBS oracle has CREDIT MEMO     |
-- | ADJUSTMENTS, UPDATE DISPUTE FLAG, REFUND FLAG which come as INBOUND|
-- | data from CAPGEMINI                                                |
-- |                                                                    |
-- |Change Record:                                                      |
-- |===============                                                     |
-- |Version    Date          Author           Remarks                   |
-- |=======    ==========    =============    ==========================|
-- |1.0        29-NOV-2011   Bapuji N         Initial version           |
-- |1.1        25-JAN-2012   Bapuji N         Added translate function  |
-- |                                          for comments              |
-- |1.2	       28-Mar-2012   Paddy            Modified to Commit False  |
-- |                                          Defect 17714, 17486       |
-- |1.3        30-Mar-2012   Bapuji N 	   Defect 17830, set dispute='N'|
-- |1.4        18-APR-2012   Bapuji N      Defect 18096, set user id to |
-- |                                       -1 for adjustement creation  |
-- |1.5        14-JUN-2012   Bapuji N      Defect 18914                 |
-- |1.6        30-Aug-2012   Rohit Ranjan  Defect# 20124                |
-- |1.7        07-Dec-2012   Sudharsan V   Defect# 21247                |
-- |1.8        04-JAN-2013   Bapuji N      Derive user and approver for |
-- |                                       Inv Adjustment Defect#21756  |
-- |1.9        08-FEB-2013   Bapuji N      Modified the approver logic  |
-- |2.0        21-FEB-2013   Bapuji N      Defect# 22375                |
-- |2.1        30-JUN-2013   Jay Gupta     Defect# 30066                |
-- |2.2        08-SEP-2014   Arun G        Defect# 31357                |
-- +====================================================================+

PROCEDURE update_process_status_prc ( p_category        IN VARCHAR2
                                    , p_customer_trx_id IN NUMBER
                                    , p_wc_id           IN VARCHAR2
                                    );

PROCEDURE update_error_status_prc ( p_category        IN VARCHAR2
                                  , p_customer_trx_id IN NUMBER
                                  , p_wc_id           IN VARCHAR2
                                  , p_error_flag      IN VARCHAR2
                                  , p_error_message   IN VARCHAR2
                                  );

PROCEDURE delete_success_trx_prc (p_days IN NUMBER);

FUNCTION validate_approval_limit( p_approver_id  NUMBER
                                , p_amount       NUMBER
                                , p_currency     VARCHAR2
                                ) RETURN VARCHAR2;

--Defect 30066 - Update ZX Schema to update partter update flags for 11i transactions to work
procedure check_zx_schema ( p_customer_trx_id NUMBER)
is

begin

  UPDATE ZX_LINES_DET_FACTORS
           SET PARTNER_MIGRATED_FLAG = NULL
         WHERE APPLICATION_ID = 222
           AND ENTITY_CODE = 'TRANSACTIONS'
           AND TRX_ID = p_customer_trx_id
           AND RECORD_TYPE_CODE = 'MIGRATED';

       UPDATE ZX_LINES
           SET manually_entered_flag = 'Y',
               last_manual_entry     = 'TAX_AMOUNT',
		       TAX_PROVIDER_ID = NULL,
               NUMERIC1 = NULL,
               NUMERIC2 = NULL,
               NUMERIC3 = NULL,
               NUMERIC4 = NULL
         WHERE TRX_ID = p_customer_trx_id;

         COMMIT;

exception
  when others then
    FND_FILE.PUT_LINE(FND_FILE.LOG, 'Exception in XX_AR_WC_AR_INBOUND.check_zx_schema: ' || SQLERRM);
end check_zx_schema;

-- +=====================================================================+
-- | Name  : main_prc                                                    |
-- | Description      : This Procedure will pull all data send from WC   |
-- |                    from custom stg table and process based on       |
-- |                    Category                                         |
-- |                                                                     |
-- | Parameters       : p_debug        IN -> Set Debug DEFAULT 'N'       |
-- |                    p_process_type IN -> Procssing Type DEFAULT 'NEW'|
-- |                    p_category     IN -> TRX CATEGORY                |
-- |                    p_invoice_id   IN -> Customer TRX ID             |
-- |                    x_retcode      OUT                               |
-- |                    x_errbuf       OUT                               |
-- +=====================================================================+
PROCEDURE main_prc( x_retcode             OUT NOCOPY  NUMBER
                  , x_errbuf              OUT NOCOPY  VARCHAR2
                  , p_debug               IN          VARCHAR2
                  , p_process_type        IN          VARCHAR2
                  , p_category            IN          VARCHAR2
                  , p_invoice_id          IN          NUMBER
                  ) AS

/* Cursor to extract all valid transactions to process CM,ADJUSTMENTS,DISPUTE and REFUND */
CURSOR c_trx_id ( p_trx_category    IN VARCHAR2
                , p_customer_trx_id IN NUMBER
                , p_and             IN VARCHAR2
                ) IS
 SELECT trx_category
      , wc_id
      , customer_trx_id
      , dispute_number
      , amount
      , reason_code
      , TRANSLATE(TRANSLATE (comments,CHR(10),' '),CHR(13),' ') comments
      , request_date
      , requested_by
      , send_refund
      , dispute_status
      , adj_activity_name rec_trx_name
   FROM xx_ar_wc_inbound_stg
  WHERE customer_trx_id        = NVL(p_customer_trx_id,customer_trx_id)
    AND trx_category           = NVL(p_trx_category,trx_category)
    AND NVL(process_flag,'N') != 'Y'
    AND ((     p_and                = 'ALL')
           OR  (p_and                = 'NEW'
    AND NVL(error_flag,'N')    = 'N')
     OR  (p_and                = 'ERRORS ONLY'
    AND NVL(error_flag,'N')    = 'Y')
     OR  (p_and                = 'ERROR SINGLE'
    AND NVL(error_flag,'N')    = 'Y'
    AND customer_trx_id        = p_customer_trx_id))
	--AND ROWNUM < 50
	--V2.1, Added following Order by Clause
	ORDER BY wc_id;


 /* Local Varibales */
ln_request_id          NUMBER;
lc_return_status       VARCHAR2(1);
lc_return_message      VARCHAR2(2000);
lr_adj_rec             ar_adjustments%ROWTYPE;
lc_adj_number          VARCHAR2(30);
ln_adj_id              NUMBER;
ln_pay_sch_id          NUMBER;
ln_main_count          NUMBER := 0;
ln_cm_count            NUMBER := 0;
ln_adj_count           NUMBER := 0;
ln_dis_count           NUMBER := 0;
ln_ref_count           NUMBER := 0;
ln_cm_s_count          NUMBER := 0;
ln_adj_s_count         NUMBER := 0;
ln_dis_s_count         NUMBER := 0;
ln_ref_s_count         NUMBER := 0;
ln_cm_f_count          NUMBER := 0;
ln_adj_f_count         NUMBER := 0;
ln_dis_f_count         NUMBER := 0;
ln_ref_f_count         NUMBER := 0;
ln_trx_id              NUMBER;
p_type                 VARCHAR2(30);
ln_bad_id_count        NUMBER := 0;
ln_purge_no            NUMBER;

ln_resp_id              NUMBER;
ln_appl_id              NUMBER;
ln_user_id              NUMBER := -1;


BEGIN

    ln_resp_id := fnd_global.resp_id;
    ln_appl_id := fnd_global.resp_appl_id;
    FND_GLOBAL.APPS_INITIALIZE(ln_user_id,ln_resp_id,ln_appl_id);

    mo_global.init(fnd_global.APPLICATION_SHORT_NAME);
    mo_global.set_policy_context('S', fnd_global.org_id);

    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'BEGINNING OF PROGRAM');
    ln_purge_no := FND_PROFILE.VALUE('XX_AR_INB_TBL_PURGE');

    FOR r_trx_id IN c_trx_id ( p_category
                             , p_invoice_id
                             , p_process_type
                             ) LOOP

        lc_return_status := FND_API.G_RET_STS_SUCCESS;
		lc_return_message := null;

        IF r_trx_id.trx_category IS NOT NULL THEN
            ln_main_count := ln_main_count + 1;
        END IF;

        BEGIN
            SELECT COUNT(*)
              INTO ln_trx_id
	      FROM ra_customer_trx_all
             WHERE customer_trx_id = r_trx_id.customer_trx_id;

            IF ln_trx_id = 0 THEN
                ln_bad_id_count   := ln_bad_id_count + 1;
                lc_return_status  := FND_API.G_RET_STS_ERROR;
                lc_return_message := 'Bad customer_trx_id send from Webcollect :' ||r_trx_id.customer_trx_id;
                FND_FILE.PUT_LINE(FND_FILE.LOG, 'Bad customer_trx_id send from Webcollect :' ||r_trx_id.customer_trx_id);
                GOTO END_OF_LOOP_CALL;
            END IF;

			--Defect 30066 - Update ZX Schema to update partter update flags for 11i transactions to work
			check_zx_schema( r_trx_id.customer_trx_id);

        EXCEPTION
            WHEN OTHERS THEN
                FND_FILE.PUT_LINE(FND_FILE.LOG, 'NO Others Raised at AR payment Schedule for :  '||r_trx_id.customer_trx_id);
                lc_return_status  := FND_API.G_RET_STS_ERROR;
                lc_return_message := 'When Others raised while validating cutomer_trx_id :  '||r_trx_id.customer_trx_id;
        END;

        IF p_debug = 'Y' THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'p_category:            '||p_category);
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'p_invoice_id:          '||p_invoice_id);
        END IF;

        IF r_trx_id.trx_category = 'CREDIT MEMO' THEN
            ln_cm_count := ln_cm_count + 1;

            IF p_debug = 'Y' THEN
                FND_FILE.PUT_LINE(FND_FILE.LOG, 'CREDIT MEMO:           ');
                FND_FILE.PUT_LINE(FND_FILE.LOG, 'trx_category:          '||r_trx_id.trx_category);
                FND_FILE.PUT_LINE(FND_FILE.LOG, 'Invoice ID:            '||r_trx_id.customer_trx_id);
                FND_FILE.PUT_LINE(FND_FILE.LOG, 'Amount:                '||r_trx_id.amount);
                FND_FILE.PUT_LINE(FND_FILE.LOG, 'Return Reason:         '||r_trx_id.reason_code);
                FND_FILE.PUT_LINE(FND_FILE.LOG, 'Comments:              '||r_trx_id.comments);
            END IF;

            create_cm_prc( P_debug             => P_debug
                         , P_category          => r_trx_id.trx_category
                         , P_customer_trx_id   => r_trx_id.customer_trx_id
                         , p_amount            => r_trx_id.amount
                         , P_reason_code       => r_trx_id.reason_code
                         , p_comments          => r_trx_id.comments
                         , p_dispute_number    => r_trx_id.dispute_number
                         , x_request_id        => ln_request_id
                         , x_return_status     => lc_return_status
                         , x_return_message    => lc_return_message
                         );

            IF p_debug = 'Y' THEN
                FND_FILE.PUT_LINE(FND_FILE.LOG, 'request id:            '||ln_request_id);
                FND_FILE.PUT_LINE(FND_FILE.LOG, 'lc_return_status:      '||lc_return_status);
                FND_FILE.PUT_LINE(FND_FILE.LOG, 'lc_return_message:     '||lc_return_message);
            END IF;

            IF lc_return_status != 'S' THEN
                FND_FILE.PUT_LINE(FND_FILE.LOG, 'CM CALL '||lc_return_message);
                update_error_status_prc ( p_category        => r_trx_id.trx_category
                                        , p_customer_trx_id => r_trx_id.customer_trx_id
                                        , p_wc_id           => r_trx_id.wc_id
                                        , p_error_flag      => 'Y'
                                        , p_error_message   => lc_return_message
                                        );

                ln_cm_f_count := ln_cm_f_count + 1;
            ELSE
                update_process_status_prc( p_category         => r_trx_id.trx_category
                                         , P_customer_trx_id  => r_trx_id.customer_trx_id
                                         , p_wc_id            => r_trx_id.wc_id
                                         );
                ln_cm_s_count := ln_cm_s_count + 1;
            END IF;

        ELSIF r_trx_id.trx_category = 'ADJUSTMENTS' THEN

            ln_adj_count := ln_adj_count + 1;

            IF p_debug = 'Y' THEN
                FND_FILE.PUT_LINE(FND_FILE.LOG, 'ADJUSTMENTS:           ');
                FND_FILE.PUT_LINE(FND_FILE.LOG, 'trx_category:          '||r_trx_id.trx_category);
                FND_FILE.PUT_LINE(FND_FILE.LOG, 'Invoice ID:            '||r_trx_id.customer_trx_id);
                FND_FILE.PUT_LINE(FND_FILE.LOG, 'Amount:                '||r_trx_id.amount);
                FND_FILE.PUT_LINE(FND_FILE.LOG, 'dispute_number:        '||r_trx_id.dispute_number);
                FND_FILE.PUT_LINE(FND_FILE.LOG, 'rec_trx_name:          '||r_trx_id.rec_trx_name);
            END IF;

            create_adj_prc( P_debug             => P_debug
                          , P_category          => r_trx_id.trx_category
                          , P_customer_trx_id   => r_trx_id.customer_trx_id
                          , P_amount            => r_trx_id.amount
                          , p_dispute_number    => r_trx_id.dispute_number
                          , p_rec_trx_name      => r_trx_id.rec_trx_name
                          , p_collector_name    => r_trx_id.requested_by
                          , p_reason_code       => r_trx_id.reason_code
                          , p_comments          => r_trx_id.comments
                          , x_new_adjust_number => lc_adj_number
                          , x_new_adjust_id     => ln_adj_id
                          , x_return_status     => lc_return_status
                          , x_return_message    => lc_return_message
                          );

            IF p_debug = 'Y' THEN
                FND_FILE.PUT_LINE(FND_FILE.LOG, 'lc_adj_number:         '||lc_adj_number);
                FND_FILE.PUT_LINE(FND_FILE.LOG, 'ln_adj_id:             '||ln_adj_id);
                FND_FILE.PUT_LINE(FND_FILE.LOG, 'lc_return_status:      '||lc_return_status);
                FND_FILE.PUT_LINE(FND_FILE.LOG, 'lc_return_message:     '||lc_return_message);
            END IF;

            IF lc_return_status != 'S' THEN
                FND_FILE.PUT_LINE(FND_FILE.LOG, 'ADJ CALL '||lc_return_message);
                update_error_status_prc ( p_category        => r_trx_id.trx_category
                                        , p_customer_trx_id => r_trx_id.customer_trx_id
                                        , p_wc_id           => r_trx_id.wc_id
                                        , p_error_flag      => 'Y'
                                        , p_error_message   => lc_return_message
                                        );

                ln_adj_f_count := ln_adj_f_count + 1;
            ELSE
                update_process_status_prc( p_category         => r_trx_id.trx_category
                                         , P_customer_trx_id  => r_trx_id.customer_trx_id
                                         , p_wc_id            => r_trx_id.wc_id
                                         );
                ln_adj_s_count := ln_adj_s_count + 1;
            END IF;

        ELSIF r_trx_id.trx_category = 'DISPUTES' THEN
            ln_dis_count := ln_dis_count + 1;

            IF p_debug = 'Y' THEN
                FND_FILE.PUT_LINE(FND_FILE.LOG, 'DISPUTES:              ');
                FND_FILE.PUT_LINE(FND_FILE.LOG, 'trx_category:          '||r_trx_id.trx_category);
                FND_FILE.PUT_LINE(FND_FILE.LOG, 'Invoice ID:            '||r_trx_id.customer_trx_id);
                FND_FILE.PUT_LINE(FND_FILE.LOG, 'dispute_status:        '||r_trx_id.dispute_status);
                FND_FILE.PUT_LINE(FND_FILE.LOG, 'dispute_number:        '||r_trx_id.dispute_number);
            END IF;

            dispute_tran_prc( P_debug             => P_debug
                            , P_category          => r_trx_id.trx_category
                            , P_customer_trx_id   => r_trx_id.customer_trx_id
                            , p_dispute_status    => r_trx_id.dispute_status
                            , p_dispute_number    => r_trx_id.dispute_number
                            , x_return_status     => lc_return_status
                            , x_return_message    => lc_return_message
                            );

	    IF p_debug = 'Y' THEN
                FND_FILE.Put_Line(FND_FILE.LOG, 'lc_return_status:      '||lc_return_status);
                FND_FILE.Put_Line(FND_FILE.LOG, 'lc_return_message:     '||lc_return_message);
            END IF;

            IF lc_return_status != 'S' THEN
                FND_FILE.Put_Line(FND_FILE.LOG, 'dispute CALL '||lc_return_message);
                update_error_status_prc ( p_category        => r_trx_id.trx_category
                                        , p_customer_trx_id => r_trx_id.customer_trx_id
                                        , p_wc_id           => r_trx_id.wc_id
                                        , p_error_flag      => 'Y'
                                        , p_error_message   => lc_return_message
                                        );
                ln_dis_f_count := ln_dis_f_count + 1;
            ELSE
                update_process_status_prc( p_category         => r_trx_id.trx_category
                                         , P_customer_trx_id  => r_trx_id.customer_trx_id
                                         , p_wc_id            => r_trx_id.wc_id
                                         );
                ln_dis_s_count := ln_dis_s_count + 1;
            END IF;

        ELSIF r_trx_id.trx_category = 'REFUNDS' THEN
            ln_ref_count := ln_ref_count + 1;

            IF p_debug = 'Y' THEN
                FND_FILE.Put_Line(FND_FILE.LOG, 'DISPUTES:              ');
                FND_FILE.Put_Line(FND_FILE.LOG, 'trx_category:          '||r_trx_id.trx_category);
                FND_FILE.Put_Line(FND_FILE.LOG, 'Invoice ID:            '||r_trx_id.customer_trx_id);
                FND_FILE.Put_Line(FND_FILE.LOG, 'send_refund:           '||r_trx_id.send_refund);
            END IF;

            refund_tran_prc( P_debug             => P_debug
                           , P_category          => r_trx_id.trx_category
                           , P_customer_trx_id   => r_trx_id.customer_trx_id
                           , p_send_refund       => r_trx_id.send_refund
                           , x_return_status     => lc_return_status
                           , x_return_message    => lc_return_message
                           );

            IF p_debug = 'Y' THEN
                FND_FILE.PUT_LINE(FND_FILE.LOG, 'lc_return_status:      '||lc_return_status);
                FND_FILE.PUT_LINE(FND_FILE.LOG, 'lc_return_message:     '||lc_return_message);
            END IF;

            IF lc_return_status != 'S' THEN
                FND_FILE.PUT_LINE(FND_FILE.LOG, 'dispute CALL '||lc_return_message);
                update_error_status_prc ( p_category        => r_trx_id.trx_category
                                        , p_customer_trx_id => r_trx_id.customer_trx_id
                                        , p_wc_id           => r_trx_id.wc_id
                                        , p_error_flag      => 'Y'
                                        , p_error_message   => lc_return_message
                                        );
                ln_ref_f_count := ln_ref_f_count + 1;
            ELSE
                update_process_status_prc( p_category         => r_trx_id.trx_category
                                         , P_customer_trx_id  => r_trx_id.customer_trx_id
                                         , p_wc_id            => r_trx_id.wc_id
                                         );
                ln_ref_s_count := ln_ref_s_count + 1;
            END IF;

        END IF;
        <<END_OF_LOOP_CALL>>
    IF lc_return_status != 'S' THEN

        update_error_status_prc ( p_category        => r_trx_id.trx_category
                                , p_customer_trx_id => r_trx_id.customer_trx_id
                                , p_wc_id           => r_trx_id.wc_id
                                , p_error_flag      => 'Y'
                                , p_error_message   => lc_return_message
                                );
    END IF;

    END LOOP;
	delete_success_trx_prc (p_days => ln_purge_no);
	FND_FILE.PUT_LINE(FND_FILE.OUTPUT, ' ');
	FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'Total Number of Transactions send by WC :          '|| ln_main_count);
	FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'Total Number of CM Transactions send by WC :       '|| ln_cm_count);
	FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'Total Number of ADJ Transactions send by WC :      '|| ln_adj_count);
	FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'Total Number of Dispute Transactions send by WC :  '|| ln_dis_count);
	FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'Total Number of Refund Transactions send by WC :   '|| ln_ref_count);
	FND_FILE.PUT_LINE(FND_FILE.OUTPUT, ' ');
	FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'Successfully Processed Transactions send by WC :   ');
	FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'Total Number of CM Transactions Processed :        '|| ln_cm_s_count);
	FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'Total Number of ADJ Transactions Processed :       '|| ln_adj_s_count);
	FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'Total Number of Dispute Transactions Processed :   '|| ln_dis_s_count);
	FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'Total Number of Refund Transactions Processed :    '|| ln_ref_s_count);
	FND_FILE.PUT_LINE(FND_FILE.OUTPUT, ' ');
	FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'Failed to Process Transactions send by WC :        ');
	FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'Total Number of CM Transactions Failed :           '|| ln_cm_f_count);
	FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'Total Number of ADJ Transactions Failed :          '|| ln_adj_f_count);
	FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'Total Number of Dispute Transactions Failed :      '|| ln_dis_f_count);
	FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'Total Number of Refund Transactions Failed :       '|| ln_ref_f_count);
	FND_FILE.PUT_LINE(FND_FILE.OUTPUT, ' ');
	FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'Total Number of Bad Transaction Numbers Send by WC '|| ln_bad_id_count);
	FND_FILE.PUT_LINE(FND_FILE.OUTPUT, ' ');
	FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'END  OF PROGRAM');
    COMMIT;
END main_prc;

-- +===================================================================+
-- | Name  : CREATE_CM_PRC                                             |
-- | Description      : This Procedure will process Credit Memo in AR  |
-- |                    based on category = 'CREDIT MEMO'              |
-- |                                                                   |
-- | Parameters      : p_debug            IN -> Set Debug DEFAULT 'N'  |
-- |                   p_category         IN -> TRX CATEGORY           |
-- |                   P_customer_trx_id  IN -> Customer TRX ID        |
-- |                   P_amount           IN -> amount                 |
-- |                   P_reason_code      IN -> return reason for CM   |
-- |                   p_comments         IN -> Comments for CM        |
-- |                   p_dispute_number   IN -> Dispute Number         |
-- |                   x_request_id       OUT                          |
-- |                   X_return_status    OUT                          |
-- |                   x_return_message   OUT                          |
-- +===================================================================+
PROCEDURE create_cm_prc( P_debug             IN         VARCHAR2
                       , P_category          IN         VARCHAR2
                       , P_customer_trx_id   IN         NUMBER
                       , p_amount            IN         NUMBER
                       , P_reason_code       IN         VARCHAR2
                       , p_comments          IN         VARCHAR2
                       , p_dispute_number    IN         VARCHAR2
                       , x_request_id        OUT        NUMBER
                       , x_return_status     OUT NOCOPY VARCHAR2
                       , x_return_message    OUT NOCOPY VARCHAR2
                       ) IS
PRAGMA AUTONOMOUS_TRANSACTION ;
 /* Local Varibales */
lc_batch_source_name    VARCHAR2(100) := 'OD_WC_CM';
lc_return_status        VARCHAR2(1);
ln_msg_count            NUMBER;
lc_msg_data             VARCHAR2(2000);
lc_api_msg              VARCHAR2(240);
ln_amount               NUMBER := 0;
ln_tax_amount           NUMBER := 0;
ln_freight_amount	NUMBER := 0;
lc_invoice_number       VARCHAR2(100);
lc_workflow_flag        VARCHAR2(1) := 'Y';
cm_line_tbl_type_cover  arw_cmreq_cover.Cm_Line_Tbl_Type_Cover;
ln_request_id           NUMBER;
ln_due_amount           NUMBER := 0;
ln_line_level_amount    NUMBER := 0;
ln_tax_level_amount     NUMBER := 0;
lc_cm_trx_id            NUMBER;
ln_customer_id          NUMBER;
ln_bill_to_id           NUMBER;
ln_ship_to_id           NUMBER;
lc_c_status             VARCHAR2(1);
lc_b_status             VARCHAR2(1);
lc_s_status             VARCHAR2(1);
ln_gl_flag_count        NUMBER;
ln_item_count           NUMBER;
ln_line_credit_flag     VARCHAR2(1) := 'N';
ln_customer_trx_line_id NUMBER ;

BEGIN
    lc_msg_data := NULL;
	lc_return_status := NULL;
	lc_api_msg := NULL;
    -- Below Variable initialization added by Vivek on 16-July-2014-----

    lc_batch_source_name:= 'OD_WC_CM';
    ln_msg_count:=NULL;
    ln_amount := 0;
    ln_tax_amount:= 0;
    ln_freight_amount:= 0;
    lc_invoice_number:=NULL;
    lc_workflow_flag:= 'Y';
    cm_line_tbl_type_cover.DELETE;
    ln_request_id:=NULL;
    ln_due_amount:= 0;
    ln_line_level_amount:= 0;
    ln_tax_level_amount:= 0;
    lc_cm_trx_id:=NULL;
    ln_customer_id:=NULL;
    ln_bill_to_id:=NULL;
    ln_ship_to_id:=NULL;
    lc_c_status:=NULL;
    lc_b_status:=NULL;
    lc_s_status:=NULL;
    ln_gl_flag_count:=NULL;
    ln_item_count:=NULL;
    ln_customer_trx_line_id := NULL;

    -- End of changes done on 16-July-2014
    IF p_debug = 'Y' THEN
        FND_FILE.Put_Line(FND_FILE.LOG, 'P_category:            '||P_category);
        FND_FILE.Put_Line(FND_FILE.LOG, 'P_customer_trx_id:     '||P_customer_trx_id);
        FND_FILE.Put_Line(FND_FILE.LOG, 'p_amount:              '||p_amount);
        FND_FILE.Put_Line(FND_FILE.LOG, 'P_reason_code:         '||P_reason_code);
        FND_FILE.Put_Line(FND_FILE.LOG, 'p_comments:            '||p_comments);
        FND_FILE.Put_Line(FND_FILE.LOG, 'p_dispute_number:      '||p_dispute_number);
    END IF;

    IF P_category = 'CREDIT MEMO' THEN

        ln_amount := (-1*p_amount);
        BEGIN
            SELECT amount_due_remaining,
                   amount_line_items_remaining,
                   tax_remaining
              INTO ln_due_amount,
                   ln_line_level_amount,
                   ln_tax_level_amount
              FROM ar_payment_schedules_all
             WHERE customer_trx_id = p_customer_trx_id;

            IF p_debug = 'Y' THEN
                FND_FILE.Put_Line(FND_FILE.LOG, 'AR payment Schedule due amount ' ||ln_due_amount|| ' for :  '||p_customer_trx_id);
            END IF;

        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                FND_FILE.Put_Line(FND_FILE.LOG, 'NO Data Found for AR payment Schedule for :  '||p_customer_trx_id);
            	lc_return_status := FND_API.G_RET_STS_ERROR;
                lc_msg_data      := lc_msg_data || ' NO Data Found for AR payment Schedule for :  '||p_customer_trx_id;
            WHEN OTHERS THEN
                FND_FILE.Put_Line(FND_FILE.LOG, 'NO Others Raised at AR payment Schedule for :  '||p_customer_trx_id);
                lc_return_status := FND_API.G_RET_STS_ERROR;
                lc_msg_data      := lc_msg_data ||' NO Others Raised at AR payment Schedule for :  '||p_customer_trx_id;
        END;

        /* Validate if customr,bill to, ship to is active or not */
    /* Process CM for inactive customers, SKIP CUSTOMER VALIDATION for DEFECT 18914 */
/*	BEGIN
	    SELECT sold_to_customer_id
	         , bill_to_site_use_id
	         , ship_to_site_use_id
	      INTO ln_customer_id
	         , ln_bill_to_id
	         , ln_ship_to_id
	      FROM ra_customer_trx_all
	     WHERE customer_trx_id = p_customer_trx_id;

	     BEGIN
	         SELECT status
	           INTO lc_c_status
	           FROM hz_cust_accounts
	          WHERE cust_account_id = ln_customer_id;

	          IF lc_c_status = 'I' THEN
	              lc_return_status := FND_API.G_RET_STS_ERROR;
	              lc_msg_data      := lc_msg_data ||' customer status is inactive for :              '||p_customer_trx_id;
	              GOTO END_OF_CM;
	          END IF;
	     EXCEPTION
	         WHEN NO_DATA_FOUND THEN
	             FND_FILE.Put_Line(FND_FILE.LOG, 'NO Data Found for customer status validation : '||p_customer_trx_id);
	             lc_return_status := FND_API.G_RET_STS_ERROR;
	             lc_msg_data      := lc_msg_data ||' NO Data Found for customer status validation : '||p_customer_trx_id;
	             GOTO END_OF_CM;
	         WHEN OTHERS THEN
	             FND_FILE.Put_Line(FND_FILE.LOG, 'NO Others Raised for customer status validation :   '||p_customer_trx_id);
	             lc_return_status := FND_API.G_RET_STS_ERROR;
	             lc_msg_data      := lc_msg_data ||' NO Others Raised for customer status validation :      '||p_customer_trx_id;
	             GOTO END_OF_CM;
	     END;

	     BEGIN
	         SELECT status
	           INTO lc_b_status
                   FROM hz_cust_site_uses_all
	          WHERE site_use_id = ln_bill_to_id;

	          IF lc_b_status = 'I' THEN
	              lc_return_status := FND_API.G_RET_STS_ERROR;
	              lc_msg_data      := lc_msg_data ||' bill_to status is inactive for :              '||p_customer_trx_id;
	              GOTO END_OF_CM;
	          END IF;
	     EXCEPTION
	         WHEN NO_DATA_FOUND THEN
	             FND_FILE.Put_Line(FND_FILE.LOG, 'NO Data Found for bill_to status validation : '||p_customer_trx_id);
	             lc_return_status := FND_API.G_RET_STS_ERROR;
	             lc_msg_data      := lc_msg_data ||' NO Data Found for bill_to status validation : '||p_customer_trx_id;
	             GOTO END_OF_CM;
	         WHEN OTHERS THEN
	             FND_FILE.Put_Line(FND_FILE.LOG, 'NO Others Raised for bill_to status validation :   '||p_customer_trx_id);
	             lc_return_status := FND_API.G_RET_STS_ERROR;
	             lc_msg_data      := lc_msg_data ||' NO Others Raised for bill_to status validation :      '||p_customer_trx_id;
	             GOTO END_OF_CM;
	     END;

	     BEGIN
	         SELECT status
	           INTO lc_s_status
                   FROM hz_cust_site_uses_all
	          WHERE site_use_id = ln_ship_to_id;

	          IF lc_s_status = 'I' THEN
	              lc_return_status := FND_API.G_RET_STS_ERROR;
	              lc_msg_data      := lc_msg_data ||' ship_to status is inactive for :              '||p_customer_trx_id;
	              GOTO END_OF_CM;
	          END IF;
	     EXCEPTION
	         WHEN NO_DATA_FOUND THEN
	             FND_FILE.Put_Line(FND_FILE.LOG, 'NO Data Found for ship_to status validation : '||p_customer_trx_id);
	             lc_return_status := FND_API.G_RET_STS_ERROR;
	             lc_msg_data      := lc_msg_data ||' NO Data Found for ship_to status validation : '||p_customer_trx_id;
	             GOTO END_OF_CM;
	         WHEN OTHERS THEN
	             FND_FILE.Put_Line(FND_FILE.LOG, 'NO Others Raised for ship_to status validation :   '||p_customer_trx_id);
	             lc_return_status := FND_API.G_RET_STS_ERROR;
	             lc_msg_data      := lc_msg_data ||' NO Others Raised for ship_to status validation :      '||p_customer_trx_id;
	             GOTO END_OF_CM;
	     END;

	EXCEPTION
	    WHEN NO_DATA_FOUND THEN
	        FND_FILE.Put_Line(FND_FILE.LOG, 'NO Data Found for customer validation :      '||p_customer_trx_id);
	        lc_return_status := FND_API.G_RET_STS_ERROR;
	        lc_msg_data      := lc_msg_data ||' NO Data Found for customer validation :      '||p_customer_trx_id;
	        GOTO END_OF_CM;
	    WHEN OTHERS THEN
	        FND_FILE.Put_Line(FND_FILE.LOG, 'NO Others Raised for customer validation :   '||p_customer_trx_id);
	        lc_return_status := FND_API.G_RET_STS_ERROR;
	        lc_msg_data      := lc_msg_data ||' NO Others Raised for customer validation :      '||p_customer_trx_id;
	        GOTO END_OF_CM;
	END;
*/
	/* GL CC status Validation */
	BEGIN
	    SELECT COUNT(*)
	      INTO ln_gl_flag_count
	      FROM gl_code_combinations         gcc
	         , ra_cust_trx_line_gl_dist_all lin
	         , ra_customer_trx_all          trx
	     WHERE gcc.detail_posting_allowed_flag <> 'Y'
	       AND gcc.code_combination_id = lin.code_combination_id
	       AND lin.customer_trx_id     = trx.customer_trx_id
	       AND trx.customer_trx_id     = p_customer_trx_id;

	     IF ln_gl_flag_count > 0 THEN
	         lc_return_status := FND_API.G_RET_STS_ERROR;
	         lc_msg_data      := lc_msg_data ||' GL CC ID is inactive :              '||p_customer_trx_id;
	         GOTO END_OF_CM;
	     END IF;
	EXCEPTION
	    WHEN NO_DATA_FOUND THEN
	        FND_FILE.Put_Line(FND_FILE.LOG, 'NO Data Found for GL CC ID validation :      '||p_customer_trx_id);
	        lc_return_status := FND_API.G_RET_STS_ERROR;
	        lc_msg_data      := lc_msg_data ||' NO Data Found for GL CC ID validation :      '||p_customer_trx_id;
	        GOTO END_OF_CM;
	    WHEN OTHERS THEN
	        FND_FILE.Put_Line(FND_FILE.LOG, 'NO Others Raised for GL CC ID validation :   '||p_customer_trx_id);
	        lc_return_status := FND_API.G_RET_STS_ERROR;
	        lc_msg_data      := lc_msg_data ||' NO Others Raised for GL CC ID validation :      '||p_customer_trx_id;
	        GOTO END_OF_CM;

	END;
	/* Item Validation for conversion data */
	BEGIN
	    SELECT COUNT(*)
	      INTO ln_item_count
	      FROM ra_customer_trx_lines_all lin
	     WHERE customer_trx_id     = p_customer_trx_id
	       AND NVL(inventory_item_id, -99)   = -99
               AND line_type = 'LINE';

	     IF ln_item_count > 0 THEN
	         lc_return_status := FND_API.G_RET_STS_ERROR;
	         lc_msg_data      := lc_msg_data ||' Item number is null :              '||p_customer_trx_id;
	         GOTO END_OF_CM;
	     END IF;

	EXCEPTION
	    WHEN NO_DATA_FOUND THEN
	        FND_FILE.Put_Line(FND_FILE.LOG, 'NO Data Found for Item no validation :      '||p_customer_trx_id);
	        lc_return_status := FND_API.G_RET_STS_ERROR;
	        lc_msg_data      := lc_msg_data ||' NO Data Found for Item no validation :      '||p_customer_trx_id;
	        GOTO END_OF_CM;
	    WHEN OTHERS THEN
	        FND_FILE.Put_Line(FND_FILE.LOG, 'NO Others Raised for Item no validation :   '||p_customer_trx_id);
	        lc_return_status := FND_API.G_RET_STS_ERROR;
	        lc_msg_data      := lc_msg_data ||' NO Others Raised for Item no validation :      '||p_customer_trx_id;
	        GOTO END_OF_CM;
	END;

      IF ln_due_amount >= p_amount THEN

       -- IF ln_due_amount = p_amount THEN
       --     ln_amount     := (-1 * ln_line_level_amount);
       --     ln_tax_amount := (-1 * ln_tax_level_amount);
          --  IF p_debug = 'Y' THEN
          --      FND_FILE.Put_Line(FND_FILE.LOG, 'ln amount is equal then :                   '||ln_amount);
          --      FND_FILE.Put_Line(FND_FILE.LOG, 'ln amount is equal then tax amt :           '||ln_tax_amount);
          --  END IF;
       -- ELSE
         --   IF p_amount >= ln_line_level_amount THEN
          --      ln_amount     := (-1 * ln_line_level_amount);
          --      ln_tax_amount := (-1 * (p_amount -ln_line_level_amount));
            --    IF p_debug = 'Y' THEN
              --      FND_FILE.Put_Line(FND_FILE.LOG, 'ln amount is not equal then :               '||ln_amount);
               --     FND_FILE.Put_Line(FND_FILE.LOG, 'ln amount is not equal then tax amt :       '||ln_tax_amount);
               -- END IF;

           -- END IF;
        --END IF;

       IF p_debug = 'Y'
       THEN
        fnd_file.put_line(fnd_file.log, 'P_reason_Code : '|| p_reason_code);
        fnd_file.put_line(fnd_file.log, 'p_amount :'||p_amount);
        fnd_file.put_line(fnd_file.log, 'ln_tax_level_amount :'||ln_tax_level_amount);
        fnd_file.put_line(fnd_file.log, 'ln_due_amount : '||ln_due_amount);

       END IF;

       ln_line_credit_flag := 'N';

       IF p_reason_code IN ( 'TAX' ,'TRE')
       THEN
         IF p_amount = ln_tax_level_amount
         THEN
           ln_tax_amount       := (-1 * ln_tax_level_amount);
           ln_amount           := 0;

           IF p_debug = 'Y' THEN
              FND_FILE.Put_Line(FND_FILE.LOG, 'ln p_amount equal to ln_tax_level_amount ');
              FND_FILE.Put_Line(FND_FILE.LOG, 'ln_tax_amount :           '||ln_tax_amount);
           END IF;
         ELSIF p_amount > ln_tax_level_amount
         THEN

             ln_amount       := (-1 * (p_amount/(ln_due_amount))* ln_line_level_amount);
             ln_tax_amount   := (-1 * (p_amount/(ln_due_amount))* ln_tax_level_amount);


            IF p_debug = 'Y' THEN
              FND_FILE.Put_Line(FND_FILE.LOG, 'ln p_amount > ln_tax_level_amount ');
              FND_FILE.Put_Line(FND_FILE.LOG, 'ln_tax_amount :           '||ln_tax_amount);
              FND_FILE.Put_Line(FND_FILE.LOG, 'ln_amount :           '||ln_amount);
            END IF;
          ELSE
             ln_tax_amount       := (-1 * p_amount) ;
             ln_amount           := 0;
            IF p_debug = 'Y' THEN
              FND_FILE.Put_Line(FND_FILE.LOG, 'ln p_amount < ln_tax_level_amount ');
              FND_FILE.Put_Line(FND_FILE.LOG, 'ln_tax_amount :           '||ln_tax_amount);
              FND_FILE.Put_Line(FND_FILE.LOG, 'ln_amount :           '||ln_amount);
            END IF;
          END IF;
         --END IF;
      ELSIF p_reason_code = 'DEL'
      THEN
       IF p_amount <= ln_line_level_amount
       THEN
         BEGIN
           SELECT customer_trx_line_id
           INTO ln_customer_trx_line_id
           FROM ra_customer_trx_lines_all rctl,
                mtl_system_items_b msi
           WHERE rctl.customer_trx_id = p_customer_trx_id
           AND msi.inventory_item_id = rctl.inventory_item_id
           AND msi.segment1 = 'DF/DL'
           AND msi.organization_id = 441
           AND rownum < 2;

         cm_line_tbl_type_cover(1).customer_trx_line_id := ln_customer_trx_line_id;
         cm_line_tbl_type_cover(1).extended_amount      := (-1) * p_amount;
         ln_line_credit_flag := 'L'; -- Line only

         IF p_debug = 'Y' THEN
              FND_FILE.Put_Line(FND_FILE.LOG, 'ln DEL p_amount <= ln_line_level_amount ');
         END IF;

         EXCEPTION
           WHEN OTHERS
           THEN
             ln_amount       := (-1 * (p_amount/(ln_due_amount))* ln_line_level_amount);
             ln_tax_amount   := (-1 * (p_amount/(ln_due_amount))* ln_tax_level_amount);

             IF p_debug = 'Y' THEN
              FND_FILE.Put_Line(FND_FILE.LOG, 'ln exception p_amount <= ln_line_level_amount ');
              FND_FILE.Put_Line(FND_FILE.LOG, 'ln_tax_amount :           '||ln_tax_amount);
              FND_FILE.Put_Line(FND_FILE.LOG, 'ln_amount :           '||ln_amount);
             END IF;

         END;

       ELSE
         ln_amount       := (-1 * (p_amount/(ln_due_amount))* ln_line_level_amount);
         ln_tax_amount   := (-1 * (p_amount/(ln_due_amount))* ln_tax_level_amount);

         IF p_debug = 'Y'
         THEN
          FND_FILE.Put_Line(FND_FILE.LOG, 'ln DEL ELSE ');
          FND_FILE.Put_Line(FND_FILE.LOG, 'ln_tax_amount :           '||ln_tax_amount);
          FND_FILE.Put_Line(FND_FILE.LOG, 'ln_amount :           '||ln_amount);
        END IF;

       END IF;

      ELSE
        IF (p_amount = ln_due_amount)
        THEN
           ln_amount     := (-1 * ln_line_level_amount);
           ln_tax_amount := (-1 * ln_tax_level_amount);
          IF p_debug = 'Y' THEN
              FND_FILE.Put_Line(FND_FILE.LOG, 'ln p_amount =  ln_due_amount ');
              FND_FILE.Put_Line(FND_FILE.LOG, 'ln_tax_amount :           '||ln_tax_amount);
              FND_FILE.Put_Line(FND_FILE.LOG, 'ln_amount :           '||ln_amount);
            END IF;
        ELSE
             ln_amount       := (-1 * (p_amount/(ln_due_amount))* ln_line_level_amount);
             ln_tax_amount   := (-1 * (p_amount/(ln_due_amount))* ln_tax_level_amount);

             IF p_debug = 'Y' THEN
              FND_FILE.Put_Line(FND_FILE.LOG, 'ln else ');
              FND_FILE.Put_Line(FND_FILE.LOG, 'ln_tax_amount :           '||ln_tax_amount);
              FND_FILE.Put_Line(FND_FILE.LOG, 'ln_amount :           '||ln_amount);
            END IF;
        END IF;
       END IF;


       ar_credit_memo_api_pub.create_request ( p_api_version                => 1.0  -- standard API parameters
                                              , p_init_msg_list              => FND_API.G_TRUE
                                              , p_commit                     => FND_API.G_FALSE  -- Defect 17714 Paddy
                                              , p_validation_level           => FND_API.G_VALID_LEVEL_FULL
                                              , x_return_status              => lc_return_status
                                              , x_msg_count                  => ln_msg_count
                                              , x_msg_data                   => lc_api_msg
                                              , p_customer_trx_id            => p_customer_trx_id -- CREDIT MEMO REQ Params
                                              , p_line_credit_flag           => ln_line_credit_flag --'N' --'L' --line 'N' --'Y' -- Line + Tax --'N' Header only
                                              , p_line_amount                => ln_amount
                                              , p_tax_amount                 => ln_tax_amount
                                              , p_freight_amount             => ln_freight_amount
                                              , p_cm_reason_code             => P_reason_code
                                              , p_comments                   => p_comments
                                              , p_orig_trx_number            => lc_invoice_number
                                              , p_tax_ex_cert_num            => NULL
                                              , p_request_url                => 'AR_CREDIT_MEMO_API_PUB.print_default_page'
                                              , p_transaction_url            => 'AR_CREDIT_MEMO_API_PUB.print_default_page'
                                              , p_trans_act_url              => 'AR_CREDIT_MEMO_API_PUB.print_default_page'
                                              , p_cm_line_tbl                => cm_line_tbl_type_cover
                                              , p_skip_workflow_flag         => lc_workflow_flag -- The following 										 --parameters are used if the CM needs to be 									       --created directly and not through WF
                                              , p_credit_method_installments => NULL
                                              , p_credit_method_rules        => NULL
                                              , p_batch_source_name          => lc_batch_source_name
                                              , x_request_id                 => ln_request_id
                                              );

        ELSE
            lc_return_status := FND_API.G_RET_STS_ERROR;
            IF lc_msg_data IS NOT NULL THEN
                lc_msg_data      := lc_msg_data||chr(10);
            END IF;
            lc_msg_data      := lc_msg_data || ' Amount send from EC is greater then trx due amt :  '||p_customer_trx_id;
        END IF;

        IF lc_return_status = 'S' THEN
            x_request_id := ln_request_id;
--            update_process_status_prc ( p_category      => p_category
--                                      , p_customer_trx_id => p_customer_trx_id
--                                      );
            BEGIN
	/*
                SELECT max(trx.customer_trx_id)
                  INTO lc_cm_trx_id
                  FROM ra_customer_trx_all trx
                     , ra_batch_sources_all src
                 WHERE src.name                      = lc_batch_source_name
                   AND src.batch_source_id           = trx.batch_source_id
                   AND trx.previous_customer_trx_id  = p_customer_trx_id
                   AND trx.attribute15              != 'P';
	*/

		SELECT cm_customer_trx_id
		  INTO lc_cm_trx_id
	          FROM ra_cm_requests_all
  	         WHERE request_id=ln_request_id;

		-- Added the following update statement for the defect 17486

		UPDATE ra_cm_requests_all
		   SET status='COMPLETE'
  	         WHERE request_id=ln_request_id;

                FND_FILE.Put_Line(FND_FILE.LOG, 'Credit Memo TRX ID IS                      :  '||lc_cm_trx_id);

                IF  lc_cm_trx_id IS NOT NULL THEN
                    UPDATE ra_customer_trx_all
                       SET attribute15        = 'P'
                         , attribute12        = p_dispute_number
                         , attribute11        = NULL
                         , attribute_category = 'SALES_ACCT'
                         , last_update_date   = SYSDATE
                         , last_updated_by    = FND_GLOBAL.user_id
                     WHERE customer_trx_id    = lc_cm_trx_id;

		-- Added the following update statement to mark dispute flag as 'N' By Bapuji Defect 17830

		    UPDATE ra_customer_trx_all
		       SET  attribute11			='N'
                          , last_update_date            = SYSDATE
                          , last_updated_by             = FND_GLOBAL.user_id
		     WHERE customer_trx_id		= p_customer_trx_id;

                     UPDATE ar_payment_schedules_all
                        SET exclude_from_cons_bill_flag = 'Y'
                          , last_update_date            = SYSDATE
                          , last_updated_by             = FND_GLOBAL.user_id
                      WHERE customer_trx_id = lc_cm_trx_id;
                END IF;

            EXCEPTION
                WHEN OTHERS THEN
                    FND_FILE.Put_Line(FND_FILE.LOG, 'WHEN OTHERS RAISED in update trx id for CM :  '||SQLERRM);
            END;
	    COMMIT;
        ELSE
	   ROLLBACK;  -- Added to rollback in case of credit memo creation failure, defect 17714 by Paddy

            IF lc_msg_data IS NOT NULL THEN
                lc_msg_data      := lc_msg_data || chr(10);
            END IF;
            IF ln_msg_count >= 1 THEN
                FOR I IN 1..ln_msg_count LOOP
                   -- lc_api_msg := I||'. '||SUBSTR(FND_MSG_PUB.Get(p_encoded => FND_API.G_FALSE ), 1, 255);
                    FND_FILE.PUT_LINE(FND_FILE.LOG, 'lc_api_msg : '|| lc_api_msg);
                    FND_FILE.PUT_LINE(FND_FILE.LOG,(I||'. '||SUBSTR(FND_MSG_PUB.Get(p_encoded => FND_API.G_FALSE ), 1, 255)));
                    IF i = 1 THEN
                        lc_api_msg := I||'. '||SUBSTR(FND_MSG_PUB.Get(p_encoded => FND_API.G_FALSE ), 1, 255);
                    END IF;
                END LOOP;
            END IF;
            lc_msg_data      := lc_msg_data || lc_api_msg ||' : '|| p_customer_trx_id;
        END IF;
        <<END_OF_CM>>
        X_return_status  := lc_return_status;
        x_return_message := SUBSTR(lc_msg_data,1,1999);

    END IF;
EXCEPTION
    WHEN OTHERS THEN
        FND_FILE.Put_Line(FND_FILE.LOG, 'WHEN OTHERS RAISED in create_cm_prc :  '||SQLERRM);
        x_return_status  := FND_API.G_RET_STS_ERROR;
        x_return_message := 'WHEN OTHERS RAISED in create_cm_prc :  '||SQLERRM;
END create_cm_prc;

-- +===================================================================+
-- | Name  : CREATE_ADJ_PRC                                            |
-- | Description      : This Procedure will process Adjustment in AR   |
-- |                    based on category = 'ADJUSTMENTS'              |
-- |                                                                   |
-- | Parameters      : p_debug            IN -> Set Debug DEFAULT 'N'  |
-- |                   p_category         IN -> TRX CATEGORY           |
-- |                   P_customer_trx_id  IN -> Customer TRX ID        |
-- |                   P_amount           IN -> amount                 |
-- |                   p_dispute_number   IN -> Dispute number         |
-- |                   p_rec_trx_name     IN -> Activity Name          |
-- |                   p_collector_name   IN -> collector name         |
-- |                   p_reason_code      IN -> Adj reason code        |
-- |                   p_comments         IN -> comments               |
-- |                   x_new_adjust_number OUT                         |
-- |                   x_new_adjust_id     OUT                         |
-- |                   X_return_status     OUT                         |
-- |                   x_return_message    OUT                         |
-- +===================================================================+
PROCEDURE create_adj_prc( P_debug             IN         VARCHAR2
                        , P_category          IN         VARCHAR2
                        , P_customer_trx_id   IN         NUMBER
                        , p_amount            IN         NUMBER
                        , p_dispute_number    IN         VARCHAR2
                        , p_rec_trx_name      IN         VARCHAR2
                        , p_collector_name    IN         VARCHAR2
                        , p_reason_code       IN         VARCHAR2
                        , p_comments          IN         VARCHAR2
                        , x_new_adjust_number OUT        VARCHAR2
                        , x_new_adjust_id     OUT        NUMBER
                        , x_return_status     OUT NOCOPY VARCHAR2
                        , x_return_message    OUT NOCOPY VARCHAR2
                        ) IS

/* Local Variables */
lr_inp_adj_rec	        ar_adjustments%ROWTYPE;
lc_return_status        VARCHAR2(1);
ln_msg_count            NUMBER;
lc_msg_data             VARCHAR2(2000);
ln_adj_number           VARCHAR2(30);
ln_adj_id               NUMBER;
lc_opu                  VARCHAR2(30);
ln_set_of_books_id      NUMBER;
ln_pay_sch_id           NUMBER;
ln_due_amount           NUMBER;
/*As per Defect# 20124*/
ln_payment_class        VARCHAR2(30);
lc_type                 VARCHAR2(30);
ln_rec_trx_id           NUMBER;
lc_api_msg              VARCHAR2(240);
ln_resp_id              NUMBER;
ln_appl_id              NUMBER;
ln_user_id              NUMBER := -1;
lc_user                 VARCHAR2(80) := NULL;
lc_approver             VARCHAR2(80) := NULL;
ln_approver_id          NUMBER;
lc_userandapprover      VARCHAR2(80);
lc_currency_code        VARCHAR2(5);
lc_app_limit_validation VARCHAR2(1) := 'N';
lc_approver_limit_check  VARCHAR2(1) := FND_API.G_TRUE;
PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
    IF p_debug = 'Y' THEN
        FND_FILE.Put_Line(FND_FILE.LOG, 'P_category:            '||P_category);
        FND_FILE.Put_Line(FND_FILE.LOG, 'P_customer_trx_id:     '||P_customer_trx_id);
        FND_FILE.Put_Line(FND_FILE.LOG, 'p_amount:              '||p_amount);
        FND_FILE.Put_Line(FND_FILE.LOG, 'p_rec_trx_name:        '||p_rec_trx_name);
        FND_FILE.Put_Line(FND_FILE.LOG, 'p_collector_name:      '||p_collector_name);
        FND_FILE.Put_Line(FND_FILE.LOG, 'p_dispute_number:      '||p_dispute_number);
    END IF;

    IF p_category = 'ADJUSTMENTS' THEN
        IF p_collector_name IS NOT NULL THEN
            -- Defect# 21756 changes start
            lc_user     := TRIM(SUBSTR(p_collector_name,1,(INSTR(p_collector_name, ',',1,1)-1)));
            lc_approver := TRIM(SUBSTR(p_collector_name,(INSTR(p_collector_name,',',1,1)+1)));
            lc_userandapprover := lc_user || '/'||lc_approver;
            IF lc_user IS NOT NULL THEN
                SELECT user_id INTO ln_user_id
                  FROM fnd_user
                 WHERE user_name = lc_user;
            END IF;
            IF lc_approver IS NOT NULL THEN
                BEGIN
                    SELECT user_id INTO ln_approver_id
                      FROM fnd_user fu
                     WHERE user_name = lc_approver
                       AND EXISTS ( SELECT 1 FROM ar_approval_user_limits aa
                                     WHERE aa.user_id = fu.user_id
                                       AND aa.document_type = 'ADJ'
                                  );
                EXCEPTION
                	WHEN NO_DATA_FOUND THEN
                        FND_FILE.Put_Line(FND_FILE.LOG, 'NO Data Found for ADJ Approver : '||lc_approver);
                        x_return_status := FND_API.G_RET_STS_ERROR;
                        x_return_message := 'NO Data Found for ADJ Approver : '||lc_approver ;
                        GOTO END_OF_API_CALL;
                    WHEN OTHERS THEN
                        FND_FILE.Put_Line(FND_FILE.LOG, 'WHEN OTHERS RAISED in deriving ADJ Approver :  '||SQLERRM);
                        x_return_status := FND_API.G_RET_STS_ERROR;
                        x_return_message := 'WHEN OTHERS RAISED in deriving ADJ Approver :  '||SQLERRM;
                        GOTO END_OF_API_CALL;
                END;
            END IF;
        END IF;
        -- Defect# 21756 changes ends
        IF P_DEBUG = 'Y' THEN
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'USER ID  :'||ln_user_id);
        END IF;
        ln_resp_id := fnd_global.resp_id;
        ln_appl_id := fnd_global.resp_appl_id;
        FND_GLOBAL.APPS_INITIALIZE(ln_user_id,ln_resp_id,ln_appl_id);
        IF P_DEBUG = 'Y' THEN
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'FND GLOBAL USER ID  :'||fnd_global.user_id);
        END IF;
        x_return_status := 'S';
        /* Derive GL_SET_OF_BOOKS_ID */
        ln_set_of_books_id := fnd_profile.value('GL_SET_OF_BKS_ID');

	IF ln_set_of_books_id IS NULL THEN
            BEGIN
                SELECT SUBSTR(name,4,2)
                  INTO lc_opu
                  FROM hr_all_organization_units_tl
                 WHERE organization_id = FND_PROFILE.VALUE('ORG_ID');

                SELECT gl.set_of_books_id
                  INTO ln_set_of_books_id
                  FROM xx_fin_translatedefinition DEF
                     , xx_fin_translatevalues val
                     , gl_sets_of_books gl
                 WHERE def.translate_id     = val.translate_id
                   AND def.translation_name = 'OD_COUNTRY_DEFAULTS'
                   AND val.source_value1    = lc_opu
                   AND val.target_value1    =  gl.short_name;

            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    FND_FILE.Put_Line(FND_FILE.LOG, 'NO Data Found for gl_set_of_books_id :  ');
                    x_return_status := FND_API.G_RET_STS_ERROR;
                    x_return_message := 'NO Data Found for gl_set_of_books_id :  ';
                WHEN OTHERS THEN
                    FND_FILE.Put_Line(FND_FILE.LOG, 'WHEN OTHERS RAISED in deriving set of books id :  '||SQLERRM);
                    x_return_status := FND_API.G_RET_STS_ERROR;
                    x_return_message := 'WHEN OTHERS RAISED in deriving set of books id :  '||SQLERRM;
            END;
	END IF;
        /*Derive payment schedule id and type of adj */
         BEGIN
            SELECT payment_schedule_id
                 , amount_due_remaining
                 , class
                 , invoice_currency_code
              INTO ln_pay_sch_id
                 , ln_due_amount
                 , ln_payment_class
				 , lc_currency_code
              FROM ar_payment_schedules_all
             WHERE customer_trx_id = p_customer_trx_id;

            /* NOTE - we don't do TAX and FREIGHT level adjustments */
            IF ln_due_amount = p_amount THEN
                lc_type := 'INVOICE';
           /* ELSIF ln_payment_class<>'CM'
            AND ln_due_amount > p_amount
                THEN  lc_type := 'LINE';
           -- ELSIF ln_payment_class='CM'
           AND ln_due_amount < p_amount
              THEN    lc_type := 'LINE';  */ -- Commented as part of the Defect # 21247

            ELSIF  LN_DUE_AMOUNT > P_AMOUNT -- Added as part of the Defect # 21247
            AND LN_DUE_AMOUNT >0
                then  LC_TYPE := 'LINE';
             ELSIF  LN_DUE_AMOUNT < P_AMOUNT
            and LN_DUE_AMOUNT <0
                then  LC_TYPE := 'LINE';


            ELSE
                x_return_status  := FND_API.G_RET_STS_ERROR;
                x_return_message := 'Adjusted Amount sent from WC is greater then due amount for cust_trx_id: '||p_customer_trx_id;
                GOTO END_OF_API_CALL;
            END IF;
			--Verify Approve has Limit to approve the transaction
            IF ln_approver_id IS NOT NULL THEN
              lc_app_limit_validation := validate_approval_limit( p_approver_id => ln_approver_id
                                                                , p_amount      => (-1 * p_amount)
                                                                , p_currency    => lc_currency_code
                                                                );
              IF lc_app_limit_validation = 'Y' THEN
                lc_approver_limit_check := FND_API.G_FALSE;
              ELSE
                lc_approver_limit_check := NULL;
				ln_approver_id          := NULL;
              END IF;

            END IF;
            IF p_debug = 'Y' THEN
              FND_FILE.Put_Line(FND_FILE.LOG, 'lc_app_limit_validation : ' || lc_app_limit_validation);
              FND_FILE.Put_Line(FND_FILE.LOG, 'lc_approver_limit_check : ' || lc_approver_limit_check);
            END IF;

        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                FND_FILE.Put_Line(FND_FILE.LOG, 'NO Data Found in AR PAYMENT SCHEDULES FOR :   '||p_customer_trx_id);
                x_return_status := FND_API.G_RET_STS_ERROR;
                x_return_message := 'NO Data Found in AR PAYMENT SCHEDULES FOR :   '||p_customer_trx_id;
            WHEN OTHERS THEN
                FND_FILE.Put_Line(FND_FILE.LOG, 'WHEN OTHERS RAISED while deriving data from AR PAY SCH :  '||SQLERRM);
                x_return_status := FND_API.G_RET_STS_ERROR;
                x_return_message := 'WHEN OTHERS RAISED while deriving data from AR PAY SCH :  '||SQLERRM;
        END;

        /* Derive receivable trx id */
        BEGIN
            SELECT receivables_trx_id
              INTO ln_rec_trx_id
              FROM ar_receivables_trx_all
             WHERE UPPER(NAME) = UPPER(p_rec_trx_name);
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                FND_FILE.Put_Line(FND_FILE.LOG, 'NO Data Found for AR Receivable Trx Name :   '||p_rec_trx_name);
                x_return_status  := FND_API.G_RET_STS_ERROR;
                x_return_message := 'NO Data Found for AR Receivable Trx Name :   '||p_rec_trx_name;
                ln_rec_trx_id    := NULL;
            WHEN OTHERS THEN
                FND_FILE.Put_Line(FND_FILE.LOG, 'WHEN OTHERS RAISED while deriving data from AR Receivable Trx Name :  '||SQLERRM);
                x_return_status  := FND_API.G_RET_STS_ERROR;
                x_return_message := 'WHEN OTHERS RAISED while deriving data from AR Receivable Trx Name :  '||SQLERRM;
                ln_rec_trx_id    := NULL;
        END;

        lr_inp_adj_rec.acctd_amount         := (-1 * p_amount);
        lr_inp_adj_rec.adjustment_id        := NULL;
        lr_inp_adj_rec.adjustment_number    := NULL;
        lr_inp_adj_rec.adjustment_type      := 'M';        --Manual
        lr_inp_adj_rec.amount               := (-1 * p_amount);
        lr_inp_adj_rec.created_by           := ln_user_id;  /*-1; --FND_GLOBAL.USER_ID; -- Defect# 21756 */
        lr_inp_adj_rec.created_from         := 'CG_WC_INBOUND_API';
        lr_inp_adj_rec.creation_date        := SYSDATE;
        lr_inp_adj_rec.gl_date              := SYSDATE;
        lr_inp_adj_rec.last_update_date     := SYSDATE;
        lr_inp_adj_rec.last_updated_by      := ln_user_id;  /*-1; --FND_GLOBAL.USER_ID; -- Defect# 21756 */
        lr_inp_adj_rec.posting_control_id   := -3;         /* -1,-2,-4 for posted in previous rel and -3 for not posted */
        lr_inp_adj_rec.set_of_books_id      := ln_set_of_books_id;
        lr_inp_adj_rec.status               := 'A';
        lr_inp_adj_rec.type                 := lc_type;     /* ADJ TYPE CHARGES,FREIGHT,INVOICE,LINE,TAX */
        lr_inp_adj_rec.payment_schedule_id  := ln_pay_sch_id;   --Derive from ar_payment_schedules_all
        lr_inp_adj_rec.apply_date           := SYSDATE;
        lr_inp_adj_rec.receivables_trx_id   := ln_rec_trx_id;
        lr_inp_adj_rec.attribute1           := lc_userandapprover;   --p_collector_name;
        lr_inp_adj_rec.customer_trx_id      := p_customer_trx_id;   -- Invoice ID for which adjustment is made
        lr_inp_adj_rec.comments             := p_comments;
        lr_inp_adj_rec.reason_code          := p_reason_code;
        lr_inp_adj_rec.approved_by          := ln_approver_id; -- Defect# 21756

        IF p_debug = 'Y' THEN
            FND_FILE.Put_Line(FND_FILE.LOG, 'lr_inp_adj_rec.acctd_amount :'||lr_inp_adj_rec.acctd_amount);
            FND_FILE.Put_Line(FND_FILE.LOG, 'ln_set_of_books_id          :'||ln_set_of_books_id);
            FND_FILE.Put_Line(FND_FILE.LOG, 'lc_type                     :'||lc_type);
            FND_FILE.Put_Line(FND_FILE.LOG, 'ln_pay_sch_id               :'||ln_pay_sch_id);
            FND_FILE.Put_Line(FND_FILE.LOG, 'ln_rec_trx_id               :'||ln_rec_trx_id);
            FND_FILE.Put_Line(FND_FILE.LOG, 'requester                   :'||ln_user_id);
            FND_FILE.Put_Line(FND_FILE.LOG, 'approver                    :'||ln_approver_id);
            FND_FILE.Put_Line(FND_FILE.LOG, 'p_dispute_number            :'||p_dispute_number);
            FND_FILE.Put_Line(FND_FILE.LOG, 'p_customer_trx_id           :'||p_customer_trx_id);
            FND_FILE.Put_Line(FND_FILE.LOG, 'x_return_status             :'||x_return_status);
        END IF;

	IF x_return_status = 'S' THEN
           xx_ar_adjust_pub.create_adjustment ( p_api_name              => 'XX_AR_WC_AR_INBOUND_TEMP_PKG'
                                            , p_api_version          => 1.0
                                            , p_init_msg_list        => FND_API.G_TRUE
                                            , p_commit_flag	         => FND_API.G_TRUE
                                            , p_validation_level     => FND_API.G_VALID_LEVEL_FULL
                                            , p_msg_count            => ln_msg_count
                                            , p_msg_data             => lc_api_msg
                                            , p_return_status        => lc_return_status
                                            , p_adj_rec              => lr_inp_adj_rec
                                            , p_chk_approval_limits  => lc_approver_limit_check
                                            , p_check_amount         => NULL
                                            , p_move_deferred_tax    => 'Y'
                                            , p_new_adjust_number    => ln_adj_number
                                            , p_new_adjust_id        => ln_adj_id
                                            , p_called_from          => NULL
                                            , p_old_adjust_id        => NULL
                                            );
            IF p_debug = 'Y' THEN
                FND_FILE.Put_Line(FND_FILE.LOG, 'lc_return_status            :'||lc_return_status);
                FND_FILE.Put_Line(FND_FILE.LOG, 'lc_msg_data                 :'||lc_msg_data);
                FND_FILE.Put_Line(FND_FILE.LOG, 'ln_adj_number               :'||ln_adj_number);
                FND_FILE.Put_Line(FND_FILE.LOG, 'ln_adj_id                   :'||ln_adj_id);
            END IF;

            IF lc_return_status = 'S' OR ln_adj_number IS NOT NULL THEN
                x_new_adjust_number := ln_adj_number;
                x_new_adjust_id     := ln_adj_id;
                UPDATE ar_adjustments_all
                   SET created_by      = ln_user_id
                     , last_updated_by = ln_user_id
                 WHERE adjustment_id   =  ln_adj_id;
                IF p_debug = 'Y' THEN
                  FND_FILE.Put_Line(FND_FILE.LOG, 'Updated created by for             :'||ln_adj_id);
                  FND_FILE.Put_Line(FND_FILE.LOG, 'Updated Row Count                  :'||SQL%ROWCOUNT);
                END IF;
            ELSE
                IF lc_msg_data IS NOT NULL THEN
                    lc_msg_data      := lc_msg_data || chr(10);
                END IF;
                IF ln_msg_count >= 1 THEN
                    FOR I IN 1..ln_msg_count LOOP
                        FND_FILE.PUT_LINE(FND_FILE.LOG, 'lc_api_msg : '|| lc_api_msg);
                        FND_FILE.PUT_LINE(FND_FILE.LOG,(I||'. '||SUBSTR(FND_MSG_PUB.Get(p_encoded => FND_API.G_FALSE ), 1, 255)));
                        IF i = 1 THEN
                            lc_api_msg := I||'. '||SUBSTR(FND_MSG_PUB.Get(p_encoded => FND_API.G_FALSE ), 1, 255);
                        END IF;
                    END LOOP;
                END IF;
                lc_msg_data      := lc_msg_data || lc_api_msg ||' : '|| p_customer_trx_id;
                x_return_message := SUBSTR(lc_msg_data,1,1999);
            END IF;
            X_return_status := lc_return_status;
        END IF;
    END IF;
    <<END_OF_API_CALL>>
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        FND_FILE.Put_Line(FND_FILE.LOG, 'WHEN OTHERS RAISED in create_adj_prc :  '||SQLERRM);
        x_return_status  := FND_API.G_RET_STS_ERROR;
        x_return_message := 'WHEN OTHERS RAISED in create_adj_prc :  '||SQLERRM;

END create_adj_prc;

-- +===================================================================+
-- | Name  : DISPUTE_TRAN_PRC                                          |
-- | Description      : This Procedure will process Disputes in AR     |
-- |                    based on category = 'DISPUTES'                 |
-- |                                                                   |
-- | Parameters      : p_debug            IN -> Set Debug DEFAULT 'N'  |
-- |                   p_category         IN -> TRX CATEGORY           |
-- |                   P_customer_trx_id  IN -> Customer TRX ID        |
-- |                   p_dispute_status   IN -> Dispute status         |
-- |                   p_dispute_number   IN -> Dispute number         |
-- |                   X_return_status    OUT                          |
-- |                   x_return_message   OUT                          |
-- +===================================================================+
PROCEDURE dispute_tran_prc( P_debug             IN         VARCHAR2
                          , P_category          IN         VARCHAR2
                          , P_customer_trx_id   IN         NUMBER
                          , p_dispute_status    IN         VARCHAR2
                          , p_dispute_number    IN         VARCHAR2
                          , x_return_status     OUT NOCOPY VARCHAR2
                          , x_return_message    OUT NOCOPY VARCHAR2
                          ) IS
BEGIN
    IF P_category = 'DISPUTES' THEN

        UPDATE ra_customer_trx_all
	   SET attribute11        = p_dispute_status
	  --   , attribute12        = p_dispute_number
               , attribute_category = 'SALES_ACCT'
               , last_update_date   = SYSDATE
               , last_updated_by    = FND_GLOBAL.user_id
           WHERE customer_trx_id    = P_customer_trx_id;

        x_return_status := FND_API.G_RET_STS_SUCCESS;
    END IF;
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        FND_FILE.Put_Line(FND_FILE.LOG, 'WHEN OTHERS RAISED in create_dispute_prc :  '||SQLERRM);
        x_return_status  := FND_API.G_RET_STS_ERROR;
        x_return_message := 'WHEN OTHERS RAISED in create_dispute_prc :  '||SQLERRM;
END dispute_tran_prc;

-- +===================================================================+
-- | Name  : REFUND_TRAN_PRC                                           |
-- | Description      : This Procedure will process Disputes in AR     |
-- |                    based on category = 'REFUNDS'                  |
-- |                                                                   |
-- | Parameters      : p_debug            IN -> Set Debug DEFAULT 'N'  |
-- |                   p_category         IN -> TRX CATEGORY           |
-- |                   P_customer_trx_id  IN -> Customer TRX ID        |
-- |                   p_send_refund   IN -> refund status             |
-- |                   X_return_status    OUT                          |
-- |                   x_return_message   OUT                          |
-- +===================================================================+
PROCEDURE refund_tran_prc( P_debug             IN         VARCHAR2
                         , P_category          IN         VARCHAR2
                         , P_customer_trx_id   IN         NUMBER
                         , p_send_refund       IN         VARCHAR2
                         , x_return_status     OUT NOCOPY VARCHAR2
                         , x_return_message    OUT NOCOPY VARCHAR2
                         ) IS
BEGIN
    IF P_category = 'REFUNDS' THEN

        UPDATE ra_customer_trx_all
           SET attribute9         = p_send_refund
             , attribute_category = 'SALES_ACCT'
             , last_update_date   = SYSDATE
             , last_updated_by    = FND_GLOBAL.user_id
         WHERE customer_trx_id = P_customer_trx_id;

        x_return_status := FND_API.G_RET_STS_SUCCESS;
    END IF;
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        FND_FILE.Put_Line(FND_FILE.LOG, 'WHEN OTHERS RAISED in refund_tran_prc :  '||SQLERRM);
        X_return_status  := FND_API.G_RET_STS_ERROR;
        x_return_message := 'WHEN OTHERS RAISED in refund_tran_prc :  '||SQLERRM;
END refund_tran_prc;

-- +===================================================================+
-- | Name  : UPDATE_PROCESS_STATUS_PRC                                 |
-- | Description      : This Procedure will update process flag for    |
-- |                    all successful transactions                    |
-- |                                                                   |
-- | Parameters      : p_category         IN -> TRX CATEGORY           |
-- |                   p_customer_trx_id  IN -> Customer TRX ID        |
-- |                   p_wc_id            IN -> WC ID                  |
-- +===================================================================+
PROCEDURE update_process_status_prc ( p_category        IN VARCHAR2
                                    , p_customer_trx_id IN NUMBER
                                    , p_wc_id           IN VARCHAR2
                                    ) IS
BEGIN
    UPDATE xx_ar_wc_inbound_stg
       SET process_flag     = 'Y'
         , error_flag       = NULL
         , error_message    = NULL
         , last_update_date = SYSDATE
         , last_updated_by  = FND_GLOBAL.user_id
     WHERE customer_trx_id  = p_customer_trx_id
       AND trx_category     = p_category
       AND wc_id            = p_wc_id;
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        FND_FILE.Put_Line(FND_FILE.LOG, 'WHEN OTHERS RAISED in updating process_flag :  '||SQLERRM);
END update_process_status_prc;

-- +===================================================================+
-- | Name  : UPDATE_ERROR_STATUS_PRC                                   |
-- | Description      : This Procedure will update errors flag and     |
-- |                    error message based on above calling api's     |
-- |                                                                   |
-- | Parameters      : p_category         IN -> TRX CATEGORY           |
-- |                   P_customer_trx_id  IN -> Customer TRX ID        |
-- |                   p_wc_id            IN -> WC ID                  |
-- |                   p_error_flag       IN -> error flag             |
-- |                   p_error_message    IN -> error message          |
-- +===================================================================+
PROCEDURE update_error_status_prc ( p_category        IN VARCHAR2
                                  , p_customer_trx_id IN NUMBER
                                  , p_wc_id           IN VARCHAR2
                                  , p_error_flag      IN VARCHAR2
                                  , p_error_message   IN VARCHAR2
                                  ) IS
BEGIN
    UPDATE xx_ar_wc_inbound_stg
       SET error_flag       = p_error_flag
         , error_message    = p_error_message
         , last_update_date = SYSDATE
         , last_updated_by  = FND_GLOBAL.user_id
     WHERE customer_trx_id = p_customer_trx_id
       AND trx_category    = p_category
       AND wc_id           = p_wc_id;
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        FND_FILE.Put_Line(FND_FILE.LOG, 'WHEN OTHERS RAISED in updating error_flag :  '||SQLERRM);
END update_error_status_prc;

-- +===================================================================+
-- | Name  : DELETE_SUCCESS_TRX_PRC                                    |
-- | Description      : This Procedure will delete successful trx id's |
-- |                    based on process flag = 'Y' and creation date  |
-- |                    less then or equal to p_days                   |
-- |                                                                   |
-- | Parameters      : p_days         IN -> No of days i.e 14          |
-- +===================================================================+
PROCEDURE delete_success_trx_prc (p_days IN NUMBER) IS
BEGIN
    DELETE FROM xx_ar_wc_inbound_stg
     WHERE NVL(process_flag,'N') = 'Y'
       AND creation_date         <= (SYSDATE - p_days);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'Total Number of records purged from stg table: '||SQL%ROWCOUNT);
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        FND_FILE.Put_Line(FND_FILE.LOG, 'WHEN OTHERS RAISED in purging from stg tbl :  '||SQLERRM);
END delete_success_trx_prc;

FUNCTION validate_approval_limit( p_approver_id  NUMBER
                                , p_amount       NUMBER
                                , p_currency     VARCHAR2
                                ) RETURN VARCHAR2 IS
v_approved VARCHAR2(1):='N';

BEGIN
  SELECT 'Y'
    INTO v_approved
    FROM DUAL
   WHERE EXISTS ( SELECT 'x'
                   FROM ar_approval_user_limits
                  WHERE document_type ='ADJ'
	                AND currency_code = p_currency
                    AND user_id      = p_approver_id
                    AND p_amount BETWEEN amount_from AND amount_to
                );
  RETURN(v_approved);

EXCEPTION
  WHEN NO_DATA_FOUND THEN
    v_approved:='N';
    RETURN(v_approved);

  WHEN OTHERS THEN
    v_approved:='N';
    RETURN(v_approved);

END validate_approval_limit;

END XX_AR_WC_AR_INBOUND_TEMP_PKG;
/



