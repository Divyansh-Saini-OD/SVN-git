CREATE OR REPLACE
PACKAGE BODY XX_AR_AB_ARCHIVE_INV_RCPT_PKG
  --+======================================================================+
  --|      Office Depot -  RICE#E3097                                      |
  --+===========================a===========================================+
  --|Name       : XX_AR_AB_ARCHIVE_INV_RCPT_PKG.pkb                        |
  --|Description: This Package is used for fetching all the likely         |
  --|             AB invoices/CMs and receipts for archiving               |
  --|                                                                      |
  --|                                                                      |
  --|                                                                      |
  --|Change Record:                                                        |
  --|===============                                                       |
  --| 05-Apr-2018   Capgemini  Intial Draft                                |
  --+======================================================================+
  --+=======================================================================+
  --| Name : POPULATE_AB_INV_RCPT                                           |
  --| Description : The POPULATE_AB_INV_RCPT proc will perform the following|
  --|                                                                       |
  --|             1. Fetch all the receipts for a particular set of         |
  --|                invoices                                               |
  --|             2. In the recursive fashion, pick all the corresponding   |
  --|                invoices/CMs                                           |
  --|             3. Check if the entire invoice-CM-receipt transaction     |
  --|                chain is fetched                                       |
  --|                                                                       |
  --| Parameters : p_rowcnt        -- This parameter is used to determine   |
  --|                                 the minimum no. of records with       |
  --|                                 complete status 'Y' to be processed   |
  --|              p_cutoff_dt     -- This parameter is used to determine   |
  --|                                 the date until which the transactions |
  --|                                 are eligible to be purged.            |
  --|              p_delete_flag   -- This parameter is used as a deciding  |
  --|                                 factor to delete the historical data  |
  --|                                 in the custom table or not.           |
  --+=======================================================================+
AS
PROCEDURE POPULATE_AB_INV_RCPT(
    x_errbuf OUT VARCHAR2 ,
    x_retcode OUT VARCHAR2 ,
    p_rowcnt      IN NUMBER ,
    p_cutoff_dt   IN VARCHAR2, 
    p_delete_flag IN VARCHAR2 DEFAULT 'N')
IS
  ln_count             NUMBER := 0;
  ln_total_count       NUMBER := 0;
  ln_total_trans_count NUMBER := 0;
  ln_level_num         NUMBER := 0;
  ln_prev_level_num    NUMBER := 0;
  ln_conc_request_id   NUMBER := NVL(FND_GLOBAL.CONC_REQUEST_ID,-1);
  l_exception          EXCEPTION;
  l_exit_exception     EXCEPTION;
  lc_trans_present     VARCHAR2(1);
  ln_entry_count       NUMBER :=0;
  ld_cutoff_dt DATE; 
  ln_count_reached NUMBER :=0;
  CURSOR lcu_fetch_inv_rcpt(pd_cutoff_dt DATE) 
  IS
    SELECT
      /*+ index(ooh, OE_ORDER_HEADERS_N7) */
      CT.customer_trx_id,
      ARAA.cash_receipt_id,
      ACRA.gl_date gl_date
    FROM ra_customer_trx CT,
      ra_terms_tl RT,
      oe_order_headers OOH,
      ar_cash_receipts ARAA,
      ar_cash_receipt_history ACRHA,
      ar_receivable_applications ACRA
    WHERE 1                          =1             
    AND CT.trx_date                 <= pd_cutoff_dt 
    AND OOH.payment_term_id          = RT.term_id
    AND OOH.orig_sys_document_ref    = CT.trx_number
    AND RT.name NOT                 IN ('CONVERSION','IMMEDIATE','SA_DEPOSIT' )
    AND batch_source_id NOT         IN (1007,1003,1008,3041)
    AND ARAA.cash_receipt_id         = ACRA.cash_receipt_id
    AND ACRA.applied_customer_Trx_id = CT.customer_Trx_id
    AND ARAA.type                   <> 'MISC'
    AND ACRHA.current_record_flag    = 'Y'
    AND ARAA.cash_receipt_id         = ACRHA.cash_receipt_id
    AND TRUNC(ACRHA.gl_date)        <= pd_cutoff_dt 
    AND TRUNC(ACRA.gl_date)         <= pd_cutoff_dt 
    AND ACRA.status                 IN ('APP', 'ACTIVITY')
    AND NOT EXISTS
      (SELECT 1
      FROM xx_ar_intstorecust_otc XAIO
      WHERE XAIO.cust_account_id = CT.bill_to_customer_id
      )
  AND NOT EXISTS
    (SELECT 1
    FROM xx_ar_invoices_cand XAIC
    WHERE NVL(XAIC.customer_trx_id,-1) = CT.customer_trx_id
    )
  AND ROWNUM < 10;
  fetch_inv_rcpt_rec lcu_fetch_inv_rcpt%ROWTYPE;
BEGIN
  FND_FILE.Put_line(FND_FILE.LOG,'Begin of program');
  --delete only if the delete flag = 'Y'
  IF NVL(p_delete_flag,'X') = 'Y' THEN
    FND_FILE.Put_line(FND_FILE.LOG,'Start of Truncate.. ');
    BEGIN
      EXECUTE IMMEDIATE 'TRUNCATE TABLE XXAPPS_HISTORY_STAGE.XX_AR_INVOICES_CAND';
      COMMIT;
    EXCEPTION
    WHEN OTHERS THEN
      FND_FILE.PUT_LINE(FND_FILE.log,'Exception in Delete statement: ' || SQLERRM);
      RAISE l_exception;
    END;
    FND_FILE.Put_line(FND_FILE.LOG,'End of Truncate. Success.');
  END IF;
  --Added for Cutoff Data change
  IF p_cutoff_dt IS NULL THEN
    ld_cutoff_dt := TRUNC(SYSDATE-(365*4)-1);
  ELSE
    ld_cutoff_dt := FND_DATE.CANONICAL_TO_DATE(p_cutoff_dt);
  END IF;
  --Default maximum records with complete flag Y to be processed as 100000
  IF p_rowcnt            IS NULL THEN
    ln_total_trans_count := 100000;
  ELSE
    ln_total_trans_count := p_rowcnt;
  END IF;
  
  BEGIN
     SELECT COUNT(*)
       INTO ln_total_count
       FROM xx_ar_invoices_cand
      WHERE complete  = 'Y';
  EXCEPTION
  WHEN OTHERS THEN
      FND_FILE.Put_line(FND_FILE.LOG,'Exception while finding total count '|| SQLERRM);
      RAISE l_exception;
  END;
  IF ln_total_count >= ln_total_trans_count THEN
     ln_entry_count := 0;
     FND_FILE.Put_line(FND_FILE.LOG,'Table already has records with Y status. Total count available: '||ln_total_count);
     RAISE l_exit_exception; -- Exit For Loop
  END IF;
  FND_FILE.Put_line(FND_FILE.LOG,'Count of existing records in the table with Y status : '||ln_total_count);
  -- Check the existing historical data records to see if they are eligible to be purged in the current run
  UPDATE_HISTORICAL_DATA(ln_conc_request_id,ld_cutoff_dt,ln_total_trans_count,ln_count_reached);
  IF ln_count_reached <> 0 THEN
    -- Will keep on looping until total target count is met or level1 query returns no records
    LOOP
      ln_entry_count := 0;
      -- Open cursor loop, which acts as level1 query which will be a starting point to find a chain for a given transaction.
      FOR fetch_inv_rcpt_rec IN lcu_fetch_inv_rcpt(ld_cutoff_dt)
      LOOP
        ln_entry_count := ln_entry_count + 1;
        -- Query to check of the transaction chosen in level1 is already present in the table. If present, skip this transaction.
        BEGIN
          SELECT 'Y'
          INTO lc_trans_present
          FROM xx_ar_invoices_cand
          WHERE customer_trx_id = fetch_inv_rcpt_rec.customer_trx_id
          AND rownum            = 1;
        EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lc_trans_present := 'N';
          FND_FILE.Put_line(FND_FILE.LOG, 'Processing starts for top_node '||fetch_inv_rcpt_rec.customer_trx_id);
        WHEN OTHERS THEN
          FND_FILE.Put_line(FND_FILE.LOG,'Exception while checking if the transaction is already present : ' || SQLERRM);
          RAISE l_exception;
        END;
        IF lc_trans_present = 'N' THEN
          BEGIN
            --Level1 insert
            INSERT
            INTO xx_ar_invoices_cand
              (
                customer_trx_id ,
                cash_receipt_id ,
                gl_date ,
                level_num,
                request_id,
                top_node
              )
              VALUES
              (
                fetch_inv_rcpt_rec.customer_trx_id,
                fetch_inv_rcpt_rec.cash_receipt_id,
                fetch_inv_rcpt_rec.gl_date,
                1,
                ln_conc_request_id,
                fetch_inv_rcpt_rec.customer_trx_id
              );
          EXCEPTION
          WHEN OTHERS THEN
            FND_FILE.Put_line(FND_FILE.LOG,'Exception in 1st level Insert: ' || SQLERRM);
            RAISE l_exception;
          END;
          COMMIT;
          --Call Build procedure to build the chain for the current top_node
          BUILD_TRANSACTION_CHAIN(fetch_inv_rcpt_rec.customer_trx_id,ln_conc_request_id);
          --Update the chain to complete Y or N as per the cutoff date criteria
          UPDATE_CHAIN_COMP_INCOMP(fetch_inv_rcpt_rec.customer_trx_id,ld_cutoff_dt,ln_conc_request_id); 
          BEGIN
            SELECT COUNT(*)
            INTO ln_total_count
            FROM xx_ar_invoices_cand
            WHERE complete     = 'Y';
          EXCEPTION
          WHEN OTHERS THEN
            FND_FILE.Put_line(FND_FILE.LOG,'Exception while finding total count '|| SQLERRM);
            RAISE l_exception;
          END;
          IF ln_total_count >= ln_total_trans_count THEN
            ln_entry_count := 0;
            FND_FILE.Put_line(FND_FILE.LOG,'Total Count of records with Complete status Y is: '||ln_total_count||'. Target met.');
            EXIT; -- Exit For Loop
          END IF;
        ELSE
          FND_FILE.Put_line(FND_FILE.LOG,'Data already present in the custom table for top_node '||fetch_inv_rcpt_rec.customer_trx_id);
        END IF;
      END LOOP; --For Loop End
      IF ln_entry_count = 0 THEN
        FND_FILE.Put_line(FND_FILE.LOG,'End of program. No more records to be processed.');
        EXIT;
      END IF;
    END LOOP; -- Exit first while loop
  END IF;
EXCEPTION
WHEN l_exception THEN
  FND_FILE.Put_line(FND_FILE.LOG,'Exception Occcured. Exiting the program with error '||SQLERRM);
WHEN l_exit_exception THEN
  NULL;
WHEN OTHERS THEN
  FND_FILE.Put_line(FND_FILE.LOG,'Unexpected Error Occured'||SQLERRM);
END POPULATE_AB_INV_RCPT;
--+=======================================================================+
--| Name : UPDATE_CHAIN_COMP_INCOMP                                       |
--| Description : The UPDATE_CHAIN_COMP_INCOMP proc will perform the      |
--|               following                                               |
--|             1. Update all the transactions for a particular set of    |
--|                invoice fetched in level1 forming a chain to           |
--|                complete = 'Y' when all the records are fetched and    |
--|                the chain is complete, or to 'N' when there is a       |
--|                record with gl_date in the last 4 years                |
--|                                                                       |
--| Parameters : p_top_node      -- This parameter is used to fetch the   |
--|                                 all the transactions belonging        |
--|                                 to a particular chain                 |
--|              p_cutoff_dt     -- This parameter is used to determine   |
--|                                 the date until which the transactions |
--|                                 are eligible to be purged.            |
--|              conc_request_id -- This is to capture the request id     |
--|                                 of the current run.                   |
--+=======================================================================+
PROCEDURE UPDATE_CHAIN_COMP_INCOMP(
    p_top_node        IN NUMBER,
    p_cutoff_date     IN DATE,
    p_conc_request_id IN NUMBER)--Added for Cutoff Data change
IS
  ln_count NUMBER :=0;
BEGIN
  UPDATE xx_ar_invoices_cand
     SET complete   = 'N',
         request_id   = p_conc_request_id
   WHERE top_node = p_top_node
     AND EXISTS
    (SELECT 1
    FROM xx_ar_invoices_cand
    WHERE 1      =1              
    AND gl_date  > p_cutoff_date 
    AND top_node = p_top_node
    );
  ln_count := SQL%ROWCOUNT;
  -- ln_count will be 0 if there are no records with gl_date > cutoffdate, hence records are safe to be marked as complete at this stage.
  IF ln_count = 0 THEN
    UPDATE xx_ar_invoices_cand
    SET complete   = 'Y',
      request_id   = p_conc_request_id
    WHERE top_node = p_top_node;
  END IF;
  COMMIT;
EXCEPTION
WHEN OTHERS THEN
  FND_FILE.PUT_LINE(FND_FILE.log,'Unexpected Error Occured inside Update Proc '||SQLERRM);
END UPDATE_CHAIN_COMP_INCOMP;
--+=======================================================================+
--| Name : UPDATE_HISTORICAL_DATA                                         |
--| Description : The UPDATE_HISTORICAL_DATA proc will perform the        |
--|               following                                               |
--|             1. Find all the transactions in the table with            |
--|                complete column value as 'N', check if the records are |
--|                eligible to be purged in the current run for the given |
--|                cutoff date. If Yes, then find additional transactions |
--|                if any which are part of the chain and then            |
--|                mark the chain as complete with status 'Y'.            |
--|                                                                       |
--| Parameters : conc_request_id -- This is to capture the request id     |
--|                                 of the current run.                   |
--|              p_cutoff_dt     -- This parameter is used to determine   |
--|                                 the date until which the transactions |
--|                                 are eligible to be purged.            |
--+=======================================================================+
PROCEDURE UPDATE_HISTORICAL_DATA(
    p_conc_request_id   IN NUMBER,
    p_cutoff_date       IN DATE,
    p_total_trans_count IN NUMBER,
    p_count_reached OUT NUMBER)
IS
  CURSOR lcu_fetch_incomp_chain(pd_cutoff_dt DATE)
  IS
    SELECT top_node
    FROM xx_ar_invoices_cand
    WHERE complete = 'N'
    GROUP BY top_node
    HAVING MAX(gl_date) <= p_cutoff_date;
  fetch_incomp_chain_rec lcu_fetch_incomp_chain%ROWTYPE;
  ld_cutoff_dt DATE;
  ln_conc_request_id   NUMBER :=0;
  l_exception          EXCEPTION;
  ln_total_count       NUMBER :=0;
  ln_total_trans_count NUMBER :=0;
  ln_count_reached     NUMBER :=1;
BEGIN
  ld_cutoff_dt         := p_cutoff_date;
  ln_conc_request_id   := p_conc_request_id;
  ln_total_trans_count := p_total_trans_count;
  -- processing incomplete chains
  FND_FILE.Put_line(FND_FILE.LOG, 'Processing starts for historical data top_node(s) with N status');
  FOR fetch_incomp_chain_rec IN lcu_fetch_incomp_chain(ld_cutoff_dt)
  LOOP
    UPDATE xx_ar_invoices_cand
    SET level_num  = 1,
      request_id   = ln_conc_request_id
    WHERE top_node = fetch_incomp_chain_rec.top_node;
    COMMIT;
    -- Build the chain for the current transaction
    BUILD_TRANSACTION_CHAIN(fetch_incomp_chain_rec.top_node,ln_conc_request_id);
    -- Update the chain to complete Y or N as per the cutoff date criteria
    UPDATE_CHAIN_COMP_INCOMP(fetch_incomp_chain_rec.top_node,ld_cutoff_dt,ln_conc_request_id);
    COMMIT;
    BEGIN
      SELECT COUNT(*)
      INTO ln_total_count
      FROM xx_ar_invoices_cand
      WHERE complete     = 'Y';
    EXCEPTION
    WHEN OTHERS THEN
      FND_FILE.Put_line(FND_FILE.LOG,'Exception while finding total count '|| SQLERRM);
      RAISE l_exception;
    END;
    IF ln_total_count   >= ln_total_trans_count THEN
      ln_count_reached := 0;
      FND_FILE.Put_line(FND_FILE.LOG,'Total Count of Historical Data Complete with status Y records '||ln_total_count);
      EXIT; -- Exit For Loop
    END IF;
  END LOOP;
  IF ln_count_reached <> 0 THEN
    FND_FILE.Put_line(FND_FILE.LOG,'Target not met after processing historical data with N records.');
  END IF;
  p_count_reached := ln_count_reached;
EXCEPTION
WHEN l_exception THEN
  FND_FILE.Put_line(FND_FILE.LOG,'Exception Occcured inside UPDATE_HISTORICAL_DATA proc while finding total count. '||SQLERRM);
WHEN OTHERS THEN
  FND_FILE.PUT_LINE(FND_FILE.log,'Unexpected Error Occured inside UPDATE_HISTORICAL_DATA Proc. '||SQLERRM);
END UPDATE_HISTORICAL_DATA;
--+=======================================================================+
--| Name : BUILD_TRANSACTION_CHAIN                                        |
--| Description : The BUILD_TRANSACTION_CHAIN proc will perform the       |
--|               following                                               |
--|             1. Build the transaction chain for a given invoice        |
--|                at level 1                                             |
--|                                                                       |
--| Parameters : p_top_node      -- This parameter is used to fetch the   |
--|                                 all the transactions belonging        |
--|                                 to a particular chain                 |
--|              conc_request_id -- This is to capture the request id     |
--|                                 of the current run.                   |
--+=======================================================================+
PROCEDURE BUILD_TRANSACTION_CHAIN(
    p_top_node        IN NUMBER,
    p_conc_request_id IN NUMBER)
IS
  ln_count NUMBER :=0;
  ld_cutoff_dt DATE;
  ln_level_num          NUMBER := 0;
  ln_prev_level_num     NUMBER := 0;
  ln_incomp_entry_count NUMBER :=0;
  ln_conc_request_id    NUMBER :=0;
  l_exception           EXCEPTION;
  ln_top_node           NUMBER:=0;
BEGIN
  ln_count           := 1;
  ln_level_num       := 2;
  ln_prev_level_num  := 1;
  ln_top_node        := p_top_node;
  ln_conc_request_id := p_conc_request_id;
  WHILE ln_count     <>0
  LOOP
    BEGIN
      INSERT
      INTO xx_ar_invoices_cand
        (
          level_num,
          cash_receipt_id,
          customer_trx_id,
          gl_date,
          request_id,
          top_node
        )
        ( SELECT DISTINCT level_num,
            cash_receipt_id,
            customer_trx_id,
            gl_date,
            request_id,
            ln_top_node
          FROM
            (SELECT ln_level_num level_num,
              cash_receipt_id,
              customer_trx_id,
              gl_date,
              ln_conc_request_id request_id
            FROM ar_receivable_applications ARAA
            WHERE ARAA.applied_customer_trx_id IN
              (SELECT customer_trx_id
              FROM xx_ar_invoices_cand
              WHERE level_num = ln_prev_level_num
              AND request_id  = ln_conc_request_id
              AND top_node    = ln_top_node
              )
            AND araa.status IN ('APP','ACTIVITY')
            AND NOT EXISTS
              (SELECT 1
              FROM xx_ar_invoices_cand
              WHERE cash_receipt_id = araa.cash_receipt_id
              AND top_node          = ln_top_node
              AND request_id        = ln_conc_request_id
              )
            UNION ALL
            SELECT ln_level_num level_num,
              cash_receipt_id,
              customer_trx_id,
              gl_date,
              ln_conc_request_id request_id
            FROM ar_receivable_applications ARAA
            WHERE applied_customer_trx_id IN
              (SELECT customer_trx_id
              FROM xx_ar_invoices_cand
              WHERE level_num = ln_prev_level_num
              AND request_id  = ln_conc_request_id
              AND top_node    = ln_top_node
              )
            AND araa.status IN ('APP','ACTIVITY')
            AND NOT EXISTS
              (SELECT 1
              FROM xx_ar_invoices_cand
              WHERE customer_trx_id = araa.customer_trx_id
              AND top_node          = ln_top_node
              AND request_id        = ln_conc_request_id
              )
            UNION ALL
            SELECT ln_level_num,
              cash_receipt_id,
              applied_customer_trx_id customer_trx_id,
              gl_date,
              ln_conc_request_id request_id
            FROM ar_receivable_applications ARAA
            WHERE CUSTOMER_TRX_ID IN
              (SELECT
                /*+ cardinality (b,10) */
                customer_trx_id
              FROM xx_ar_invoices_cand b
              WHERE level_num = ln_prev_level_num
              AND request_id  = ln_conc_request_id
              AND top_node    = ln_top_node
              )
            AND araa.status IN ('APP','ACTIVITY')
            AND NOT EXISTS
              (SELECT 1
              FROM xx_ar_invoices_cand
              WHERE cash_receipt_id = araa.cash_receipt_id
              AND top_node          = ln_top_node
              AND request_id        = ln_conc_request_id
              )
            UNION ALL
            SELECT ln_level_num,
              cash_receipt_id,
              applied_customer_trx_id customer_trx_id,
              gl_date,
              ln_conc_request_id
            FROM ar_receivable_applications ARAA
            WHERE CUSTOMER_TRX_ID IN
              (SELECT
                /*+ cardinality (b,10) */
                customer_trx_id
              FROM xx_ar_invoices_cand b
              WHERE level_num = ln_prev_level_num
              AND request_id  = ln_conc_request_id
              AND top_node    = ln_top_node
              )
            AND araa.status IN ('APP','ACTIVITY')
            AND NOT EXISTS
              (SELECT 1
              FROM xx_ar_invoices_cand
              WHERE customer_trx_id = araa.customer_trx_id
              AND top_node          = ln_top_node
              AND request_id        = ln_conc_request_id
              )
            UNION ALL
            SELECT ln_level_num,
              NULL cash_receipt_id,
              applied_customer_trx_id customer_trx_id,
              gl_date,
              ln_conc_request_id
            FROM ar_receivable_applications ARAA
            WHERE cash_receipt_id IN
              (SELECT cash_receipt_id
              FROM xx_ar_invoices_cand
              WHERE level_num = ln_prev_level_num
              AND request_id  = ln_conc_request_id
              AND top_node    = ln_top_node
              )
            AND araa.status IN ('APP','ACTIVITY')
            AND NOT EXISTS
              (SELECT 1
              FROM xx_ar_invoices_cand
              WHERE cash_receipt_id = araa.cash_receipt_id
              AND top_node          = ln_top_node
              AND request_id        = ln_conc_request_id
              )
            UNION ALL
            SELECT ln_level_num,
              NULL cash_receipt_id,
              applied_customer_trx_id customer_trx_id,
              gl_date,
              ln_conc_request_id
            FROM ar_receivable_applications ARAA
            WHERE CASH_RECEIPT_ID IN
              (SELECT cash_receipt_id
              FROM xx_ar_invoices_cand
              WHERE level_num = ln_prev_level_num
              AND request_id  = ln_conc_request_id
              AND top_node    = ln_top_node
              )
            AND araa.status IN ('APP','ACTIVITY')
            AND NOT EXISTS
              (SELECT 1
              FROM xx_ar_invoices_cand
              WHERE customer_trx_id = araa.customer_trx_id
              AND top_node          = ln_top_node
              AND request_id        = ln_conc_request_id
              )
            AND applied_customer_trx_id IS NOT NULL  
            ) XX_INV_RCP
          WHERE NOT EXISTS
            (SELECT 1
            FROM xx_ar_invoices_cand
            WHERE customer_trx_id = XX_INV_RCP.customer_trx_id
            AND top_node          = ln_top_node
            AND request_id        = ln_conc_request_id
            )
          AND NOT EXISTS
            (SELECT 1
            FROM xx_ar_invoices_cand
            WHERE cash_receipt_id = XX_INV_RCP.cash_receipt_id
            AND top_node          = ln_top_node
            AND request_id        = ln_conc_request_id
            )
        );
      ln_count := SQL%ROWCOUNT;
      COMMIT;
    EXCEPTION
    WHEN OTHERS THEN
      FND_FILE.Put_line(FND_FILE.LOG,'Exception in Level '||ln_level_num||' Insert ::' || SQLERRM);
      RAISE l_exception;
    END;
    IF ln_count = 0 THEN
      EXIT;
    ELSE
      ln_prev_level_num := ln_level_num;
      ln_level_num      := ln_level_num + 1;
    END IF;
  END LOOP; -- Exit inner while loop
  COMMIT;
  FND_FILE.Put_line(FND_FILE.LOG,'Total Level(s) '||ln_prev_level_num||' for top_node '||ln_top_node);    
EXCEPTION
WHEN l_exception THEN
  FND_FILE.Put_line(FND_FILE.LOG,'Exception Occcured inside BUILD_TRANSACTION_CHAIN Proc. Exiting the program with error '||SQLERRM);
WHEN OTHERS THEN
  FND_FILE.PUT_LINE(FND_FILE.log,'Unexpected Error Occured inside BUILD_TRANSACTION_CHAIN Proc '||SQLERRM);
END BUILD_TRANSACTION_CHAIN;
END XX_AR_AB_ARCHIVE_INV_RCPT_PKG;
/