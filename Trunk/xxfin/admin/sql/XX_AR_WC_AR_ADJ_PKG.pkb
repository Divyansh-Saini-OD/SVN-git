create or replace 
PACKAGE BODY XX_AR_WC_AR_ADJ_PKG AS
-- +====================================================================+
-- |                  Office Depot - Project Simplify                   |
-- |                  Office Depot                                      |
-- +====================================================================+
-- | Name  : XX_AR_WC_AR_ADJ_PKG                                        |
-- | Rice ID : I2161                                                    |
-- | Description  : This package contains procedures related to the     |
-- | Web collect data to be processed in EBS oracle has                 |
-- | ADJUSTMENTS which come as INBOUND                                  |
-- | data from CAPGEMINI                                                |
-- |                                                                    |
-- |Change Record:                                                      |
-- |===============                                                     |
-- |Version    Date          Author           Remarks                   |
-- |=======    ==========    =============    ==========================|
-- |1.0        7-APR-2016   Madhan Sanjeevi   Initial version           |
-- |                                          Created for Defect# 36366 |
-- |1.1        13-MAY-2016  Madhan Sanjeevi   Modified for Defect# 37843|
-- +====================================================================+
PROCEDURE update_process_status_prc ( p_category        IN VARCHAR2
                                    , p_customer_trx_id IN NUMBER
                                    , p_wc_id           IN VARCHAR2
									, p_adj_id          IN NUMBER
                                    );
PROCEDURE update_error_status_prc ( p_category        IN VARCHAR2
                                  , p_customer_trx_id IN NUMBER
                                  , p_wc_id           IN VARCHAR2
                                  , p_error_flag      IN VARCHAR2
                                  , p_error_message   IN VARCHAR2
                                  );
PROCEDURE SALESREP_END_DATE_PRC;
FUNCTION validate_approval_limit( p_approver_id  NUMBER
                                , p_amount       NUMBER
                                , p_currency     VARCHAR2
                                ) RETURN VARCHAR2;

-- +=====================================================================+
-- | Name  : main_prc                                                    |
-- | Description      : This Procedure will pull all data send from WC   |
-- |                    from custom stg table and process based on       |
-- |                    Category - Adjustment                            |
-- |                                                                     |
-- | Parameters       : p_debug        IN -> Set Debug DEFAULT 'N'       |
-- |                    p_process_type IN ->Processing Type DEFAULT 'NEW'|
-- |                    p_category     IN -> TRX CATEGORY                |
-- |                    p_invoice_id   IN -> Customer TRX ID             |
-- |                    x_retcode      OUT                               |
-- |                    x_errbuf       OUT                               |
-- +=====================================================================+
PROCEDURE main_prc( x_retcode             OUT NOCOPY  NUMBER
                  , x_errbuf              OUT NOCOPY  VARCHAR2
                  , p_debug               IN          VARCHAR2
                  , p_invoice_id          IN          NUMBER
				  , p_cre_adj             IN          VARCHAR2 
				  , p_appr_adj            IN          VARCHAR2 DEFAULT 'N'
                  ) AS

/* Cursor to extract all valid transactions to process ADJUSTMENTS*/
CURSOR c_trx_id (p_customer_trx_id IN NUMBER
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
    AND NVL(process_flag,'N') != 'Y'
    AND NVL(error_flag,'N')    = 'Y'
    AND trx_category = 'ADJUSTMENTS' 
	AND error_message like '1. AR_AAPI_NO_CUSTOMER_TRX_ID (PAYMENT_SCHEDULE_ID=%'
	ORDER BY wc_id;

CURSOR c_trx_id_appr (p_customer_trx_id in NUMBER) IS
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
	  , error_flag
	  , error_message
   FROM xx_ar_wc_inbound_stg
  WHERE customer_trx_id        = NVL(p_customer_trx_id,customer_trx_id)
  AND trx_category = 'ADJUSTMENTS'
  AND process_flag = 'Y'
  AND error_message is not null;


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
ln_user_id              NUMBER;
p_category             VARCHAR2(30) := 'ADJUSTMENTS';

v_msg_count  number(4); 
v_msg_data  varchar2(1000); 
v_return_status  varchar2(5); 
p_count  NUMBER; 
v_old_adjustment_id  ar_adjustments.adjustment_id%type;  
v_new_adjustment_id ar_adjustments.adjustment_id%type; 
v_adj_rec  ar_adjustments%rowtype; 

--Local Variables for Approval

l_user                 VARCHAR2(80) := NULL;
l_user_id              NUMBER;
l_approver             VARCHAR2(80) := NULL;
l_approver_id          NUMBER;
l_userandapprover      VARCHAR2(80);
l_app_limit_validation VARCHAR2(1) := 'N';
l_approver_limit_check  VARCHAR2(1) := FND_API.G_TRUE;
l_currency_code          VARCHAR2(30);
x_return_status          VARCHAR2(30);
x_return_message         VARCHAR2(1000);

BEGIN

    ln_resp_id := fnd_global.resp_id;
    ln_appl_id := fnd_global.resp_appl_id;
	ln_user_id := 23228;--Greg Zuraw  -- fnd_global.user_id;
    FND_GLOBAL.APPS_INITIALIZE(ln_user_id,ln_resp_id,ln_appl_id);

    mo_global.init(fnd_global.APPLICATION_SHORT_NAME);
    mo_global.set_policy_context('S', fnd_global.org_id);

    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'BEGINNING OF PROGRAM');
    --ln_purge_no := FND_PROFILE.VALUE('XX_AR_INB_TBL_PURGE');
   IF upper(p_cre_adj) = 'Y' THEN
    FOR r_trx_id IN c_trx_id ( p_invoice_id
                             ) LOOP

        lc_return_status := FND_API.G_RET_STS_SUCCESS;
		lc_return_message := null;

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
										 , p_adj_id           => ln_adj_id
                                         );
                ln_adj_s_count := ln_adj_s_count + 1;
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
	FND_FILE.PUT_LINE(FND_FILE.OUTPUT, ' ');
	FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'Total Number of ADJ Transactions send by WC :      '|| ln_adj_count);
	FND_FILE.PUT_LINE(FND_FILE.OUTPUT, ' ');
	FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'Successfully Processed Transactions send by WC :   ');
	FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'Total Number of ADJ Transactions Processed :       '|| ln_adj_s_count);
	FND_FILE.PUT_LINE(FND_FILE.OUTPUT, ' ');
	FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'Failed to Process Transactions send by WC :        ');
	FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'Total Number of ADJ Transactions Failed :          '|| ln_adj_f_count);
	FND_FILE.PUT_LINE(FND_FILE.OUTPUT, ' ');
	FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'Total Number of Bad Transaction Numbers Send by WC '|| ln_bad_id_count);
	FND_FILE.PUT_LINE(FND_FILE.OUTPUT, ' ');
	FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'END  OF PROGRAM');
    COMMIT;
	END IF;
	-- Below SALESREP_END_DATE_PRC added for Defect# 37843
	-- Starts here for Defect# 37843
	FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'Beginging of SALESREP_END_DATE_PRC');
	SALESREP_END_DATE_PRC;
	FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'Ending of SALESREP_END_DATE_PRC');
	-- Ends here for Defect# 37843
	IF upper(p_appr_adj) = 'Y' THEN
	    ln_adj_count := 0;
		ln_adj_s_count := 0;
		ln_adj_f_count :=0;
	    FOR r_trx_id_appr IN c_trx_id_appr ( p_invoice_id
                             ) LOOP
        x_return_status := 'S';
        lc_return_status := FND_API.G_RET_STS_SUCCESS;
		lc_return_message := null;
		ln_adj_count := ln_adj_count + 1;
		
            IF p_debug = 'Y' THEN
                FND_FILE.PUT_LINE(FND_FILE.LOG, 'Approving ADJUSTMENTS:           ');
                FND_FILE.PUT_LINE(FND_FILE.LOG, 'trx_category:          '||r_trx_id_appr.trx_category);
                FND_FILE.PUT_LINE(FND_FILE.LOG, 'Invoice ID:            '||r_trx_id_appr.customer_trx_id);
                FND_FILE.PUT_LINE(FND_FILE.LOG, 'Amount:                '||r_trx_id_appr.amount);
                FND_FILE.PUT_LINE(FND_FILE.LOG, 'Adjustment ID :        '||r_trx_id_appr.error_message);
                FND_FILE.PUT_LINE(FND_FILE.LOG, 'rec_trx_name:          '||r_trx_id_appr.rec_trx_name);
            END IF;
		v_adj_rec.type := 'INVOICE';
		-- Below logic added for Adjustment to be approved for whole amount
		-- Starts for Defect# 37843 
		BEGIN
		    SELECT payment_schedule_id INTO v_adj_rec.payment_schedule_id 
			  FROM ar_payment_schedules_all 
			 WHERE customer_trx_id = p_invoice_id;
		EXCEPTION 
		    WHEN OTHERS THEN
			     FND_FILE.Put_Line(FND_FILE.LOG, 'Not able to found the payment_schedule id for the customer_trx_id : '||p_invoice_id);
		END;
		-- Ends here for Defect# 37843
	    IF r_trx_id_appr.requested_by IS NOT NULL THEN
            -- Defect# 21756 changes start
            l_user     := TRIM(SUBSTR(r_trx_id_appr.requested_by,1,(INSTR(r_trx_id_appr.requested_by, ',',1,1)-1)));
            l_approver := TRIM(SUBSTR(r_trx_id_appr.requested_by,(INSTR(r_trx_id_appr.requested_by,',',1,1)+1)));
            l_userandapprover := l_user || '/'||l_approver;
            IF l_user IS NOT NULL THEN
                SELECT user_id INTO l_user_id
                  FROM fnd_user
                 WHERE user_name = l_user;
            END IF;
            IF l_approver IS NOT NULL THEN
                BEGIN
                    SELECT user_id INTO l_approver_id
                      FROM fnd_user fu
                     WHERE user_name = l_approver
                       AND EXISTS ( SELECT 1 FROM ar_approval_user_limits aa
                                     WHERE aa.user_id = fu.user_id
                                       AND aa.document_type = 'ADJ'
                                  );
                EXCEPTION
                	WHEN NO_DATA_FOUND THEN
                        FND_FILE.Put_Line(FND_FILE.LOG, 'NO Data Found for ADJ Approver : '||l_approver);
                        x_return_status := FND_API.G_RET_STS_ERROR;
                        x_return_message := 'NO Data Found for ADJ Approver : '||l_approver ;
                   --     GOTO END_OF_API_APRV_CALL;
                    WHEN OTHERS THEN
                        FND_FILE.Put_Line(FND_FILE.LOG, 'WHEN OTHERS RAISED in deriving ADJ Approver :  '||SQLERRM);
                        x_return_status := FND_API.G_RET_STS_ERROR;
                        x_return_message := 'WHEN OTHERS RAISED in deriving ADJ Approver :  '||SQLERRM;
                   --     GOTO END_OF_API_APRV_CALL;
                END;
            END IF;
        END IF;
        -- Defect# 21756 changes ends
        IF P_DEBUG = 'Y' THEN
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'USER ID  :'||l_user_id);
		  FND_FILE.PUT_LINE(FND_FILE.LOG, 'l_approver_id :' || l_approver_id);
        END IF;
        ln_resp_id := fnd_global.resp_id;
        ln_appl_id := fnd_global.resp_appl_id;
        FND_GLOBAL.APPS_INITIALIZE(l_approver_id,ln_resp_id,ln_appl_id);
        IF P_DEBUG = 'Y' THEN
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'FND GLOBAL USER ID  :'||fnd_global.user_id);
        END IF;
		IF fnd_global.org_id = 403 THEN
		   l_currency_code := 'CAD';
		ELSE
		   l_currency_code := 'USD';
		END IF;
		v_return_status := null;
		--Verify Approve has Limit to approve the transaction
        IF l_approver_id IS NOT NULL THEN
              l_app_limit_validation := validate_approval_limit( p_approver_id => l_approver_id
                                                                , p_amount      => (-1 * r_trx_id_appr.amount)
                                                                , p_currency    => l_currency_code
                                                                );
              IF l_app_limit_validation = 'Y' THEN
                l_approver_limit_check := FND_API.G_FALSE;
              ELSE
                l_approver_limit_check := NULL;
				l_approver_id          := NULL;
              END IF;

            END IF;
            IF p_debug = 'Y' THEN
              FND_FILE.Put_Line(FND_FILE.LOG, 'l_app_limit_validation : ' || l_app_limit_validation);
              FND_FILE.Put_Line(FND_FILE.LOG, 'l_approver_limit_check : ' || l_approver_limit_check);
             END IF;
		--IF x_return_status = 'S' THEN
	         AR_ADJUST_PUB.Approve_Adjustment( 
                p_api_name => 'AR_ADJUST_PUB', 
                p_api_version => 1.0, 
                p_msg_count => v_msg_count , 
                p_msg_data => v_msg_data, 
                p_return_status => v_return_status, 
                p_adj_rec => v_adj_rec, 
                p_old_adjust_id => r_trx_id_appr.error_message
				); 
		--END IF;
		IF v_return_status = 'S' THEN
		    BEGIN
			  ln_adj_s_count := ln_adj_s_count + 1;
			  UPDATE xx_ar_wc_inbound_stg
			  SET error_message = null
			    , last_update_date = SYSDATE
                , last_updated_by  = FND_GLOBAL.user_id
              WHERE customer_trx_id = r_trx_id_appr.customer_trx_id
              AND trx_category    = r_trx_id_appr.trx_category
              AND wc_id           = r_trx_id_appr.wc_id; 
			  COMMIT;
			EXCEPTION
			  WHEN OTHERS THEN
			    FND_FILE.PUT_LINE(FND_FILE.LOG, 'Not able to Approve Adjustment ID :        '||r_trx_id_appr.error_message);  
			END;
		ELSE 
		    ln_adj_f_count := ln_adj_f_count + 1;
		END IF;
	--	<<END_OF_API_APRV_CALL>>
		END LOOP;
		COMMIT;
		
		FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'Total Number of ADJ Transactions Picked for Approval :       '|| ln_adj_count);
		FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'Total Number of ADJ Transactions Approved :       '|| ln_adj_s_count);
		FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'Total Number of ADJ Transactions Failed :          '|| ln_adj_f_count);
	END IF;
END main_prc;	

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
           ar_adjust_pub.create_adjustment ( p_api_name              => 'XX_AR_WC_AR_INBOUND_PKG'
                                            , p_api_version          => 1.0
                                            , p_init_msg_list        => FND_API.G_TRUE
                                            , p_commit_flag	         => FND_API.G_TRUE
                                            , p_validation_level     => FND_API.G_VALID_LEVEL_FULL
                                            , p_msg_count            => ln_msg_count
                                            , p_msg_data             => lc_api_msg
                                            , p_return_status        => lc_return_status
                                            , p_adj_rec              => lr_inp_adj_rec
                                          --  , p_chk_approval_limits  => lc_approver_limit_check
                                          --  , p_check_amount         => NULL
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
									, p_adj_id          IN NUMBER
                                    ) IS
BEGIN
    UPDATE xx_ar_wc_inbound_stg
       SET process_flag     = 'Y'
         , error_flag       = NULL
         , error_message    = p_adj_id
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

-- +===================================================================+
-- | Name  : SALESREP_END_DATE_PRC                                     |
-- | Description      : This Procedure will remove primary_salesrep_id |
-- |                  from ra_customer_trx_all table if there is issue |
-- |                  This Procedure created for Defect# 37843         |       
-- +===================================================================+
PROCEDURE SALESREP_END_DATE_PRC IS
BEGIN
    FOR trx_cur IN (SELECT customer_trx_id
                      FROM ar_adjustments_all aaa
                     WHERE status                 = 'W'
                       AND aaa.customer_trx_id NOT IN
                   (SELECT rct.customer_trx_id 
                      FROM JTF_RS_SALESREPS SR,
                           PER_ALL_ASSIGNMENTS_F SR_PER,
                           RA_CUSTOMER_TRX_ALL RCT,
                           AR_ADJUSTMENTS_ALL ARA
                     WHERE 1                           = 1
                       AND ARA.status                    = 'W'
                       AND ARA.customer_trx_id           = RCT.customer_trx_id
                       AND RCT.primary_salesrep_id       = SR.salesrep_id(+)
                       AND SR.person_id                  = SR_PER.person_id(+) 
                       AND NVL(SR_PER.primary_flag, 'Y') = 'Y'
                       AND RCT.trx_date BETWEEN NVL(SR_PER.effective_start_date, RCT.trx_date) AND NVL(SR_PER.effective_end_date, RCT.trx_date)
                       AND SR_PER.assignment_type (+) = 'E'
                     )
                    )
	LOOP
	BEGIN
        FND_FILE.Put_Line(FND_FILE.LOG, 'Update Primary_Salesrep_id to null for the Customer_Trx_id :'|| trx_cur.customer_trx_id);
		UPDATE ra_customer_trx_all
           SET primary_salesrep_id = NULL
         WHERE customer_trx_id  = trx_cur.customer_trx_id;
        COMMIT;
	EXCEPTION
	    WHEN OTHERS THEN
		     FND_FILE.Put_Line(FND_FILE.LOG, 'Not able to update primary_salesrep_id in RA_CUSTOMER_TRX_ALL :  '||SQLERRM);
	END;
	END LOOP;
EXCEPTION
    WHEN OTHERS THEN
        FND_FILE.Put_Line(FND_FILE.LOG, 'WHEN OTHERS RAISED in salesrep_end_date Procedure :  '||SQLERRM);
END SALESREP_END_DATE_PRC;

END XX_AR_WC_AR_ADJ_PKG;
/