SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY XX_AR_PREPYAMENT_PKG
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                Oracle  Consulting Organization                    |
-- +===================================================================+
-- | Name        :  XX_AR_PREPYAMENT_PKG.pkb                           |
-- | Description :Extension is used to reprocess the failed Prepayment  |
-- |              programs by updating the receipts with the correct    |
-- |              customer details and then re-submitting the failed    |
-- |              prepayments                                           |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version    Date         Author           Remarks                   |
-- |========   ===========  ===============  ==========================|
-- | 1.0       01-JUN-2008   P.Suresh                                  |
-- |                                                                   |
-- | 1.1       30-JUL-2008   P.Suresh        Defect : 9391. Made the   |
-- |                                         program to complete normal|
-- |                                         even if reprocessing fails|
-- |                                                                   |
-- | 1.2       14-AUG-2008   Manovinayak A   Added logic for updating  |
-- |                      Wipro Technologies  ar_cash_receipts table   |
-- |                                         with correct customer     |
-- |                                         information as a fix for  |
-- |                                         the defect#8724           |
-- |                                                                   |
-- | 1.3       21-AUG-2008   Sowmya M S      Defect : 10039 - Removed  |
-- |                           Wipro         hard coded values(Wait    |
-- |                                         Interval, Max Wait Time)  |
-- |                                         and added parameters.     |
-- |1.4       06-Apr-2017  Leela        Modified to fix Defect#40754
-- +===================================================================+
AS

PROCEDURE reprocess_prepayment(
                       x_errbuf              OUT NOCOPY VARCHAR2
                      ,x_retcode             OUT NOCOPY VARCHAR2
                      ,p_hours               IN         NUMBER
                      ,p_submit_pre          IN         VARCHAR2
                      ,p_interval            IN         NUMBER         -- Added for defect : 10039
                      ,p_max_wait            IN         NUMBER         -- Added for defect : 10039
                     )
IS

CURSOR c_prepay IS SELECT  request_id
  FROM  fnd_concurrent_programs FCP,
        fnd_concurrent_requests FCR
  WHERE FCP.concurrent_program_name = 'ARPREMAT'
   AND  FCP.concurrent_program_id   = FCR.concurrent_program_id
   AND  FCR.phase_code              = 'R'
   AND  FCR.responsibility_id       = FND_GLOBAL.RESP_ID;

CURSOR  c_ai_child_reqs IS
SELECT  request_id
  FROM  fnd_concurrent_programs FCP,
        fnd_concurrent_requests FCR
  WHERE FCP.concurrent_program_name = 'RAXTRX'
   AND  FCP.concurrent_program_id   = FCR.concurrent_program_id
   AND  FCR.request_date            > (SYSDATE - p_hours/24)
   AND  FCR.responsibility_id       = FND_GLOBAL.RESP_ID
   AND  FCR.phase_code              <> 'R';

CURSOR c_pre_sub_reqs IS
SELECT FCR.request_id
  FROM fnd_concurrent_requests FCR
 WHERE FCR.parent_request_id  =  FND_GLOBAL.CONC_REQUEST_ID;

--Added c_cust_trx Cursor for the defect#8724
CURSOR c_cust_trx (p_request_id NUMBER) IS
SELECT RCT.trx_date
      ,RCT.request_id
      ,ACT.receipt_number
      ,RCT.trx_number
      ,RCT.bill_to_site_use_id
      ,ACT.customer_site_use_id
      ,RCT.bill_to_customer_id
      ,ACT.pay_from_customer
      ,ACT.cash_receipt_id
FROM   ar_cash_receipts_all     ACT
      ,ra_customer_trx_all      RCT
      ,ar_payment_schedules_all PS
WHERE (RCT.trx_number               = ACT.attribute7
OR     RCT.attribute13              = ACT.customer_receipt_reference )
AND   PS.customer_trx_id            = RCT.customer_trx_id
AND   RCT.request_id                = p_request_id
AND   PS.status                     = 'OP'
AND   RCT.org_id                    = FND_PROFILE.VALUE('ORG_ID')
AND   NVL(RCT.prepayment_flag, 'N') = 'Y'
AND   RCT.bill_to_site_use_id       <> ACT.customer_site_use_id
AND   RCT.bill_to_customer_id       <> ACT.pay_from_customer
ORDER BY RCT.trx_date DESC ;

--Start 40754
CURSOR c_cust_trx_pmt_set (p_request_id NUMBER) IS
SELECT distinct RCTA.payment_set_id
      ,OP.payment_set_id op_payment_set_id
	  ,OP.header_id
	  ,ARAA.payment_set_id araa_payment_set_id
      ,RCT.trx_date
      ,RCT.request_id
      ,ACT.receipt_number
      ,RCT.trx_number
      ,RCT.bill_to_site_use_id
      ,ACT.customer_site_use_id
      ,RCT.bill_to_customer_id
      ,ACT.pay_from_customer
      ,ACT.cash_receipt_id
FROM   ar_cash_receipts_all     ACT
      ,ra_customer_trx_all      RCT
      ,ar_payment_schedules_all PS
	  ,oe_payments OP
	  ,oe_order_headers_all OOHA
	  ,ar_receivable_applications_all ARAA
	  ,ra_customer_trx_lines_all RCTA
	  ,oe_payments OP1
WHERE (RCT.trx_number               = ACT.attribute7
OR     RCT.attribute13              = ACT.customer_receipt_reference )
AND   PS.customer_trx_id            = RCT.customer_trx_id
AND   RCTA.customer_trx_id          = RCT.customer_trx_id
AND   RCT.request_id                = p_request_id
AND   PS.status                     = 'OP'
AND   RCT.org_id                    = FND_PROFILE.VALUE('ORG_ID')
AND   NVL(RCT.prepayment_flag, 'N') = 'Y'
AND   ARAA.cash_receipt_id = ACT.cash_receipt_id
AND   ARAA.applied_payment_schedule_id = -7
AND   ARAA.display = 'Y'
AND   RCTA.payment_set_id       <> ARAA.payment_set_id
AND   (RCT.trx_number = OOHA.order_number
OR    RCT.attribute13 = OOHA.orig_sys_document_ref)
AND   OOHA.header_id = OP.header_id
AND   OP.payment_set_id <> RCTA.payment_set_id 
AND OP1.header_id = OOHA.header_id
AND OP1.payment_set_id = ARAA.payment_set_id
AND RCTA.payment_set_id IS NOT NULL; 
--END 40754

TYPE autoinv_req_tbl IS TABLE OF c_ai_child_reqs%ROWTYPE INDEX BY BINARY_INTEGER;
lt_ai_child_reqs autoinv_req_tbl;
l_count         NUMBER := 0;
ln_request_id   NUMBER;
ln_update_cnt   NUMBER := 0;  --Added for the defect#8724
ln_customer_site_use_id  ar_cash_receipts_all.customer_site_use_id%TYPE;  --Added for the defect#8724
ln_pay_from_customer     ar_cash_receipts_all.pay_from_customer%TYPE;     --Added for the defect#8724
l_request_data  VARCHAR2(240);
flg             BOOLEAN := TRUE;
l_phase         VARCHAR2(1000);
l_status        VARCHAR2(1000);
l_dev_phase     VARCHAR2(1000);
l_dev_status    VARCHAR2(1000);
l_complete      BOOLEAN := FALSE;
l_pre_flg       VARCHAR2(1) := 'N';
l_posi1 NUMBER;
l_sub_request_id number;
l_conc_phase            VARCHAR2(80);
l_conc_status           VARCHAR2(80);
l_conc_dev_phase        VARCHAR2(30);
l_conc_dev_status       VARCHAR2(30);
l_message               VARCHAR2(240);

BEGIN
l_request_data := FND_CONC_GLOBAL.REQUEST_DATA;

/*
IF l_request_data IS NOT NULL THEN
    WHILE l_request_data IS NOT NULL LOOP
           l_posi1 := INSTRB(l_request_data, ' ', 1, 1);
           l_sub_request_id := TO_NUMBER(SUBSTRB(l_request_data , 1, l_posi1-1));
           FND_FILE.PUT_LINE(FND_FILE.LOG, 'Checking Status of Sub Request ' || to_char(l_sub_request_id));
           -- Check return status of validation request.
           IF (FND_CONCURRENT.GET_REQUEST_STATUS(
                 request_id  => l_sub_request_id,
                 phase       => l_conc_phase,
                 status      => l_conc_status,
                 dev_phase   => l_conc_dev_phase,
                 dev_status  => l_conc_dev_status,
                 message     => l_message)) THEN
             IF l_conc_dev_phase <> 'COMPLETE'
                OR l_conc_dev_status <> 'NORMAL' THEN
               x_retcode := 2;
               FND_FILE.PUT_LINE(FND_FILE.LOG,
                                 TO_CHAR( l_sub_request_id ) ||
                                 ' : ' || l_conc_phase || ':' || l_conc_status ||
                                 ' (' || l_message || ').' );
               RETURN;

             END IF;
           ELSE
             x_retcode := 2;
             RETURN;
           END IF;
           l_request_data := SUBSTRB( l_request_data , l_posi1 + 1 );
      END LOOP;
      RETURN;
*/

IF l_request_data IS NOT NULL THEN

   OPEN c_pre_sub_reqs;
   LOOP
   FETCH c_pre_sub_reqs INTO l_sub_request_id;
   EXIT WHEN c_pre_sub_reqs%NOTFOUND;

   IF (FND_CONCURRENT.GET_REQUEST_STATUS(
                 request_id  => l_sub_request_id,
                 phase       => l_conc_phase,
                 status      => l_conc_status,
                 dev_phase   => l_conc_dev_phase,
                 dev_status  => l_conc_dev_status,
                 message     => l_message)) THEN
             /*
             IF l_conc_dev_phase <> 'COMPLETE'
                OR l_conc_dev_status <> 'NORMAL' THEN
                 -- Defect 9391 x_retcode := 2;
                FND_FILE.PUT_LINE(FND_FILE.LOG, 'The Prepayment Request  ' || TO_CHAR( l_sub_request_id ) ||
                                 ' : ' || l_conc_phase || ':' || l_conc_status || ' (' || l_message || ').' );
                -- Defect 9391. RETURN;

             END IF;
             */
             FND_FILE.PUT_LINE(FND_FILE.LOG, '*****  The Prepayment Request  ' || TO_CHAR( l_sub_request_id ) ||
                                 ' : ' || l_conc_phase || ':' || l_conc_status || ' (' || l_message || ').' );

    ELSE
         x_retcode := 2;
         RETURN;
    END IF;
    END LOOP;
    CLOSE c_pre_sub_reqs;
    RETURN;

ELSE
    /* Wait if any of the prepayment program is running */

    WHILE (flg) LOOP

         OPEN c_prepay;
         LOOP
            FETCH c_prepay INTO ln_request_id;
            IF c_prepay%rowcount = 0 THEN
               flg := FALSE;
            END IF;
            EXIT WHEN c_prepay%notfound;
            l_complete := FND_CONCURRENT.WAIT_FOR_REQUEST(
                       request_id=>ln_request_id,
                       interval=>p_interval,--60,              -- Added for defect : 10039
                       max_wait=>p_max_wait,--3600,            -- Added for defect : 10039
                       phase=>l_phase,
                       status=>l_status,
                       dev_phase=>l_dev_phase,
                       dev_status=>l_dev_status,
                       message=>l_message);
            IF l_dev_phase <> 'COMPLETE' THEN
               x_errbuf := ' The Prepayment request ' || ln_request_id || ' is running more than 1 hour. Please check.';
               x_retcode := 2;
               RETURN;
            END IF;
         END LOOP;
         CLOSE c_prepay;
     END LOOP;

   OPEN  c_ai_child_reqs;
   FETCH c_ai_child_reqs BULK COLLECT INTO lt_ai_child_reqs;
   CLOSE c_ai_child_reqs;
   IF lt_ai_child_reqs.COUNT <> 0 THEN
      FOR  i IN 1..lt_ai_child_reqs.COUNT
      LOOP
          		  --Start 40754
				   ln_update_cnt := 0;
				   FOR c_cust_trx_pmt_set_rec IN c_cust_trx_pmt_set(lt_ai_child_reqs(i).request_id)
				   LOOP
				   
				      BEGIN
					      
						  UPDATE OE_PAYMENTS
						  SET payment_set_id = c_cust_trx_pmt_set_rec.payment_set_id
						  WHERE header_id = c_cust_trx_pmt_set_rec.header_id;
						  
						  UPDATE ar_receivable_applications_all
						  SET payment_set_id = c_cust_trx_pmt_set_rec.payment_set_id
						  WHERE cash_receipt_id = c_cust_trx_pmt_set_rec.cash_receipt_id
						  AND display = 'Y'
						  AND applied_payment_schedule_id = -7;
						  
						  ln_update_cnt := ln_update_cnt + SQL%ROWCOUNT;
					  EXCEPTION

                         WHEN NO_DATA_FOUND THEN

                         FND_FILE.PUT_LINE(FND_FILE.LOG,'Payment_set_id Update failed for the receipt number : '||c_cust_trx_pmt_set_rec.receipt_number||' and for the trx_number : '||c_cust_trx_pmt_set_rec.trx_number);

                         WHEN OTHERS THEN

                         FND_FILE.PUT_LINE(FND_FILE.LOG,'Payment_set_id Update failed for the receipt number : '||c_cust_trx_pmt_set_rec.receipt_number||' and for the trx_number : '||c_cust_trx_pmt_set_rec.trx_number);
                       END;
					   COMMIT;
				    END LOOP;
		
		          IF (ln_update_cnt > 0) THEN
                   fnd_request.set_org_id(FND_PROFILE.VALUE('ORG_ID'));
                   ln_request_id := FND_REQUEST.SUBMIT_REQUEST
                                        ( application => 'AR'
                                        , program     => 'ARPREMAT'
                                        , description => NULL
                                        , start_time  => SYSDATE
                                        , sub_request => FALSE
                                        , argument1   => 'AutoInvoice Batch'
                                        , argument2   => lt_ai_child_reqs(i).request_id
                                        ); 
										

                   COMMIT;
                   FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'Submitted prepayment matching program for the auto invoice request ' || lt_ai_child_reqs(i).request_id);
				   END IF;	
					--END 40754
		  
		    FND_FILE.PUT_LINE(FND_FILE.LOG,'Processing Prepayment for autoinvoice request ' || lt_ai_child_reqs(i).request_id);
          SELECT  COUNT(1)
            INTO  l_count
            FROM  fnd_concurrent_programs FCP,
                  fnd_concurrent_requests FCR
           WHERE  FCP.concurrent_program_name = 'ARPREMAT'
             AND  FCP.concurrent_program_id   = FCR.concurrent_program_id
             AND  FCR.status_code             = 'C'
             AND  FCR.argument2               = lt_ai_child_reqs(i).request_id;

          IF l_count < 1 THEN
                --- No Success Prepayment
                IF p_submit_pre = 'Y' THEN

                   -------------------------------------------
                   --Code changes for the defect#8724 begins
                   -------------------------------------------

                         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'------------------------CUSTOMER INFORMATION UPDATED-----------------------------------------------------------');
                         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,' ');
                         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,RPAD('RECEIPT ID',15,' ')
                                                         ||RPAD('RECEIPT NUMBER',20,' ')
                                                         ||RPAD('PREVIOUS CUSTOMER ID ',20,' ')
                                                         ||RPAD('PREVIOUS CUSTOMER SITE USE ID',35,' ')
                                                         ||RPAD('NEW CUSTOMER ID',20,' ')
                                                         ||RPAD('NEW CUSTOMER SITE USE ID',35,' '));

                   ln_update_cnt := 0;

                   FOR c_cust_trx_rec IN c_cust_trx(lt_ai_child_reqs(i).request_id)
                   LOOP

                       BEGIN

                         ln_customer_site_use_id := c_cust_trx_rec.customer_site_use_id;
                         ln_pay_from_customer    := c_cust_trx_rec.pay_from_customer;

                         UPDATE ar_cash_receipts_all
                         SET    customer_site_use_id = c_cust_trx_rec.bill_to_site_use_id
                               ,pay_from_customer    = c_cust_trx_rec.bill_to_customer_id
                         WHERE  cash_receipt_id      = c_cust_trx_rec.cash_receipt_id;

                         ln_update_cnt := ln_update_cnt + SQL%ROWCOUNT;

                         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,RPAD(c_cust_trx_rec.cash_receipt_id,15,' ')
                                                         ||RPAD(c_cust_trx_rec.receipt_number,20,' ')
                                                         ||RPAD(ln_pay_from_customer,20,' ')
                                                         ||RPAD(ln_customer_site_use_id,35,' ')
                                                         ||RPAD(c_cust_trx_rec.bill_to_customer_id,20,' ')
                                                         ||RPAD(c_cust_trx_rec.bill_to_site_use_id,35,' '));

                       EXCEPTION

                         WHEN NO_DATA_FOUND THEN

                         FND_FILE.PUT_LINE(FND_FILE.LOG,'Update failed for the receipt number : '||c_cust_trx_rec.receipt_number||' and for the trx_number : '||c_cust_trx_rec.trx_number);

                         WHEN OTHERS THEN

                         FND_FILE.PUT_LINE(FND_FILE.LOG,'Update failed for the receipt number : '||c_cust_trx_rec.receipt_number||' and for the trx_number : '||c_cust_trx_rec.trx_number);
                       END;


                   END LOOP;

                   IF ln_update_cnt = 0 THEN

                   FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'There were no rows to be updated');
                   FND_FILE.PUT_LINE(FND_FILE.OUTPUT,' ');

                   END IF;
				   

                   -------------------------------------------
                   --Code changes for the defect#8724 ends
                   -------------------------------------------

                   ln_request_id := FND_REQUEST.SUBMIT_REQUEST
                                        ( application => 'AR'
                                        , program     => 'ARPREMAT'
                                        , description => NULL
                                        , start_time  => NULL
                                        , sub_request => TRUE
                                        , argument1   => 'AutoInvoice Batch'
                                        , argument2   => lt_ai_child_reqs(i).request_id
                                        );

                   COMMIT;
                   FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'Submitted prepayment matching program for the auto invoice request ' || lt_ai_child_reqs(i).request_id);
                 ELSE
                   FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'Need to run prepayment matching program for the auto invoice request   ' || lt_ai_child_reqs(i).request_id);
                   FND_FILE.PUT_LINE(FND_FILE.LOG, 'Need to run prepayment matching program for the auto invoice request   ' || lt_ai_child_reqs(i).request_id);
                 END IF;
                 l_pre_flg := 'Y';
          ELSE
              FND_FILE.PUT_LINE(FND_FILE.LOG, 'The prepayment matching program for the auto invoice request ' || lt_ai_child_reqs(i).request_id || ' was successful. No need to reprocess. ');
          END IF;
      END LOOP;
      IF p_submit_pre = 'Y' and l_pre_flg = 'Y' THEN
         l_request_data :=  FND_GLOBAL.CONC_REQUEST_ID;
         fnd_conc_global.set_req_globals(conc_status => 'PAUSED', request_data=> TO_CHAR(l_request_data ));
      END IF;

      IF l_pre_flg  = 'N' THEN
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'No Prepayment program to process. Please continue with other processes ...');
      END IF;
   ELSE
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'No Autoinvoice program submitted and completed in last ' ||p_hours || ' hours . Please continue with other processes ...');
   END IF;
 END IF;
END reprocess_prepayment;

END XX_AR_PREPYAMENT_PKG;
/
SHOW ERR