SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating Package Body XX_IBY_SETTLE_BKP_PKG

PROMPT Program exits if the creation is not successful

WHENEVER SQLERROR CONTINUE

CREATE OR REPLACE PACKAGE BODY XX_IBY_SETTLE_BKP_PKG
AS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                       WIPRO Technologies                          |
-- +===================================================================+
-- | Name        : Settlement and Payment Processing                   |
-- | RICE ID     : I0349   settlement                                  |
-- | Description : To take backup and reprocess the Settlement records |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date          Author              Remarks                |
-- |=======  ===========  ==================    =======================|
-- |1.0      29-MAY-2008  Gowri Shankar         Initial version        |
-- |                                                                   |
-- +===================================================================+

-- +===================================================================+
-- | Name : BULKINSERT                                                 |
-- | Description : To insert into the Backup  tables                   |
-- |                 XX_IBY_BATCH_TRXNS_HIST_BKP,                      |
-- |                        XX_IBY_BATCH_TRXN_201_HIST_BKP             |
-- |                                                                   |
-- | Returns:                                                          |
-- +===================================================================+

    PROCEDURE BULKINSERT
    (
       p_payment_batch IN VARCHAR2
    )
    IS

        TYPE xx_iby_batch_trxns_type IS TABLE OF xx_iby_batch_trxns_history%ROWTYPE;

        ltab_xx_iby_batch_trxns_type xx_iby_batch_trxns_type;

        TYPE xx_iby_batch_trxns_det_type IS TABLE OF xx_iby_batch_trxns_201_history%ROWTYPE;

        ltab_xx_iby_bat_trx_det_typ xx_iby_batch_trxns_det_type;

        CURSOR c_insert_from_101_history
        IS
        (
            SELECT * 
            FROM xx_iby_batch_trxns_history
            WHERE ixipaymentbatchnumber = p_payment_batch
        );

        CURSOR c_insert_from_201_history 
        IS
        (
            SELECT *
            FROM xx_iby_batch_trxns_201_history
            WHERE ixipaymentbatchnumber = p_payment_batch
        );

        ln_delete_101      NUMBER;     --Defect 2972
        ln_delete_201      NUMBER;     --Defect 2972

    BEGIN

        --Bulk Inserting into XX_IBY_BATCH_TRXNS_HIST_BKP
        OPEN c_insert_from_101_history;
        LOOP

            --Added LIMIT condition to limit records to 50000
            FETCH c_insert_from_101_history BULK COLLECT INTO ltab_xx_iby_batch_trxns_type LIMIT 50000;         

                FORALL i IN ltab_xx_iby_batch_trxns_type.FIRST..ltab_xx_iby_batch_trxns_type.LAST

                    INSERT
                    INTO xx_iby_batch_trxns_hist_bkp
                    VALUES ltab_xx_iby_batch_trxns_type(i);

                    EXIT WHEN c_insert_from_101_history%NOTFOUND;

        END LOOP;

        DBMS_OUTPUT.PUT_LINE('Inserted into table: XX_IBY_BATCH_TRXNS_HIST_BKP');
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Inserted into table: XX_IBY_BATCH_TRXNS_HIST_BKP');

        CLOSE c_insert_from_101_history;

        --Bulk Inserting into XX_IBY_BATCH_TRXN_201_HIST_BKP
        OPEN c_insert_from_201_history;
        LOOP

            --Added LIMIT condition to limit records to 50000
            FETCH c_insert_from_201_history BULK COLLECT INTO ltab_xx_iby_bat_trx_det_typ LIMIT 50000;          

            FORALL i IN ltab_xx_iby_bat_trx_det_typ.FIRST..ltab_xx_iby_bat_trx_det_typ.LAST

                INSERT
                INTO xx_iby_batch_trxn_201_hist_bkp
                VALUES ltab_xx_iby_bat_trx_det_typ(i);

                EXIT WHEN c_insert_from_201_history%NOTFOUND;

        END LOOP;

        DBMS_OUTPUT.PUT_LINE('Inserted into table: XX_IBY_BATCH_TRXN_201_HIST_BKP');
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Inserted into table: XX_IBY_BATCH_TRXNS_HIST_BKP');

        CLOSE c_insert_from_201_history;

    END BULKINSERT;

-- +===================================================================+
-- | Name : CAPTURE                                                    |
-- | Description : To insert into the Backup  tables                   |
-- |                 XX_IBY_BATCH_TRXNS_HIST_BKP,                      |
-- |                        XX_IBY_BATCH_TRXN_201_HIST_BKP             |
-- |                                                                   |
-- | Returns:                                                          |
-- +===================================================================+
  
    PROCEDURE PROCESS (
                       x_error_buf             OUT VARCHAR2
                      ,x_ret_code              OUT NUMBER
                      ,p_payment_batch         IN VARCHAR2)
    IS

        CURSOR c_receipts_from_101_history
        IS
        (
        SELECT *
        FROM   xx_iby_batch_trxns_hist_bkp
        WHERE ixipaymentbatchnumber = p_payment_batch
        );

        lc_receipt_number               ar_cash_receipts_all.receipt_number%TYPE;
        ln_amount                       ar_cash_receipts_all.amount%TYPE;
        ln_cash_receipt_id              ar_cash_receipts_all.cash_receipt_id%TYPE;
        ln_cust_account_id              hz_cust_accounts.cust_account_id%TYPE;
        lc_oapfaction                   VARCHAR2(1000);
        lc_error_buf                    VARCHAR2(4000);
        ln_ret_code                     NUMBER;

        lc_error_loc                    VARCHAR2(4000);
        lc_error_debug                  VARCHAR2(4000);

        lc_unique_reference             ar_cash_receipts_all.unique_reference%TYPE;
        lc_payment_server_order_num     ar_cash_receipts_all.payment_server_order_num%TYPE;
        lc_currency_code                ar_cash_receipts_all.currency_code%TYPE;
        lc_receipt_ref                  VARCHAR2(4000);

    BEGIN

        lc_error_loc     := 'BulkInserting';
        lc_error_debug   := '';

        BULKINSERT(p_payment_batch);
        COMMIT;

        FOR lcu_receipts_from_101_history IN c_receipts_from_101_history
        LOOP

            ln_cash_receipt_id := NULL;
            lc_unique_reference := NULL;
            lc_payment_server_order_num := NULL;
            lc_currency_code := NULL;
            lc_receipt_number := NULL;
            lc_payment_server_order_num :=NULL;
            lc_oapfaction := NULL;
            ln_amount := NULL;

         BEGIN

            lc_error_loc     := 'Deriving Receipt Number';
            lc_error_debug   := 'ixreceiptnumber: '||lcu_receipts_from_101_history.ixreceiptnumber;
        
            lc_receipt_number := SUBSTR(lcu_receipts_from_101_history.ixreceiptnumber, 1
                                   ,INSTR(lcu_receipts_from_101_history.ixreceiptnumber,'#',1,1)-1);

            lc_payment_server_order_num := SUBSTR(lcu_receipts_from_101_history.ixreceiptnumber, INSTR(lcu_receipts_from_101_history.ixreceiptnumber,'#',1,2)+1);


            lc_error_loc     := 'Getting Account Number';
            lc_error_debug   := 'ixreceiptnumber: '||lcu_receipts_from_101_history.ixreceiptnumber||' ixcustaccountno: '||lcu_receipts_from_101_history.ixcustaccountno;

            SELECT HCA.cust_account_id
            INTO   ln_cust_account_id
            FROM   hz_cust_accounts HCA
            WHERE  HCA.account_number = lcu_receipts_from_101_history.ixcustaccountno;

            lc_error_loc     := 'Getting Receipt Number';
            lc_error_debug   := 'ixreceiptnumber: '||lcu_receipts_from_101_history.ixreceiptnumber||' Cust Account id: '||ln_cust_account_id||' ixamount: '||ln_amount;

            BEGIN

                SELECT 
                     ACR.cash_receipt_id
                    ,ACR.unique_reference
                    ,ACR.payment_server_order_num
                    ,ACR.currency_code
                INTO   
                     ln_cash_receipt_id
                    ,lc_unique_reference
                    ,lc_payment_server_order_num
                    ,lc_currency_code
                FROM   ar_cash_receipts_all ACR
                WHERE  ACR.receipt_number = lc_receipt_number
                AND    ACR.pay_from_customer = ln_cust_account_id;

            EXCEPTION WHEN TOO_MANY_ROWS THEN

            lc_error_loc     := 'Getting Receipt Number -- Amount';
            lc_error_debug   := 'ixreceiptnumber: '||lcu_receipts_from_101_history.ixreceiptnumber||' Cust Account id: '||ln_cust_account_id||' ixamount: '||ln_amount;
 
                SELECT
                     ACR.cash_receipt_id
                    ,ACR.unique_reference
                    ,ACR.payment_server_order_num
                    ,ACR.currency_code
                INTO   
                     ln_cash_receipt_id
                    ,lc_unique_reference
                    ,lc_payment_server_order_num
                    ,lc_currency_code
                FROM   ar_cash_receipts_all ACR
                WHERE  ACR.receipt_number = lc_receipt_number
                AND    ACR.pay_from_customer = ln_cust_account_id
                AND    ACR.amount = ln_amount;

            END;

            IF (lcu_receipts_from_101_history.ixtransactiontype = 'Sale') THEN

                lc_oapfaction := 'oracapture';
                ln_amount := lcu_receipts_from_101_history.ixamount/100;

                lc_error_loc     := 'Calling the CAPTURE  API -- XX_IBY_SETTLE_BKP_PKG';
                lc_error_debug   := 'Cash Receipt ID: '||ln_cash_receipt_id;


                XX_IBY_SETTLEMENT_PKG.CAPTURE(
                        x_error_buf           => lc_error_buf
                       ,x_ret_code            => ln_ret_code
                       ,p_cash_receipt_id     => ln_cash_receipt_id
                       ,p_cash_receipt_number => lc_receipt_number
                       ,p_receipt_amount      => ln_amount
                       ,p_receipt_currency    => lc_currency_code
                       ,p_customernumber      => ln_cust_account_id
                       ,p_oapfstoreid         => '001099'
                       ,p_oapforder_id        => lc_payment_server_order_num 
                 );

            ELSE

                lc_oapfaction := 'orareturn';
                ln_amount := -(lcu_receipts_from_101_history.ixamount/100);

              lc_error_loc     := 'Calling the RETURN API';
              lc_error_debug   := 'Cash Receipt ID: '||ln_cash_receipt_id;

               XX_IBY_SETTLEMENT_PKG.PRE_CAPTURE_CCRETUNRN(
                                       x_error_buf   => lc_error_buf
                                      ,x_ret_code    => ln_ret_code
                                      ,x_receipt_ref => lc_receipt_ref
                                      ,p_oapfaction  =>  lc_oapfaction
                                      ,p_oapfcurrency => lc_currency_code
                                      ,p_oapfamount   => ln_amount
                                      ,p_oapfstoreid  => '001099'
                                      ,p_oapftransactionid => null
                                      ,p_oapftrxn_ref      => lc_unique_reference
                                      ,p_oapforder_id      => lc_payment_server_order_num
                                      ); 
                  

            END IF;

            --DBMS_OUTPUT.PUT_LINE('x_ret_code: '||ln_ret_code||' x_error_buf: '||lc_error_buf||
              -- ' ixreceiptnumber: '||lcu_receipts_from_101_history.ixreceiptnumber);

            FND_FILE.PUT_LINE(FND_FILE.LOG,'x_ret_code: '||ln_ret_code||' x_error_buf: '||lc_error_buf||' ixreceiptnumber: '||lcu_receipts_from_101_history.ixreceiptnumber);

         EXCEPTION
         WHEN OTHERS THEN

            FND_FILE.PUT_LINE(FND_FILE.LOG,'x_ret_code: '||ln_ret_code||' x_error_buf: '||lc_error_buf||' ixreceiptnumber: '||lcu_receipts_from_101_history.ixreceiptnumber);

         END;

        END LOOP;

        DELETE FROM xx_iby_batch_trxns_history 
        WHERE ixipaymentbatchnumber = p_payment_batch;

        DELETE FROM xx_iby_batch_trxns_201_history 
        WHERE ixipaymentbatchnumber = p_payment_batch;

        COMMIT;

    EXCEPTION 
        WHEN OTHERS THEN
            --DBMS_OUTPUT.PUT_LINE('Error Message: '||SQLERRM);
            --DBMS_OUTPUT.PUT_LINE('Error Debug: '||lc_error_loc);
            --DBMS_OUTPUT.PUT_LINE('Error Location: '||lc_error_debug);
            FND_FILE.PUT_LINE(FND_FILE.LOG,'Error Message: '||SQLERRM);
            FND_FILE.PUT_LINE(FND_FILE.LOG,'Error Debug: '||lc_error_loc);
            FND_FILE.PUT_LINE(FND_FILE.LOG,'Error Location: '||lc_error_debug);

    END PROCESS;

END XX_IBY_SETTLE_BKP_PKG;
/
SHOW ERR