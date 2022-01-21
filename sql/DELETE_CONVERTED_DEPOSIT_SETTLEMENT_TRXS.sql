-- +============================================================================================+ 
-- |  Office Depot - Project Simplify                                                           | 
-- |  Providge Consulting                                                                       | 
-- +============================================================================================+ 
-- |  Name:  DELETE_CONVERTED_DEPOSIT_SETTLEMENT_TRXS                                           | 
-- |  Description:  This SQL Script will be used to delete all settlement transactions in       |
-- |                iPayment (XX_IBY_BATCH_TRXNS) that would be sent to AJB.  This will prevent |
-- |                the credit card payment from being charged again, since it has already      |
-- |                been processed in the legacy system.                                        |
-- |                                                                                            |
-- |  Parameters:   REQUEST_ID - Request Id for the deposit records that need to be remitted.   |
-- |                             The script can be run multiple times if more than one          |
-- |                             request_id exists for the converted open-deposit records.      |
-- |                                                                                            |
-- |  Change Record:                                                                            | 
-- +============================================================================================+ 
-- | Version     Date         Author           Remarks                                          | 
-- | =========   ===========  =============    ===============================================  | 
-- | 1.0         21-Feb-2008  B.Looman         Initial version                                  | 
-- +============================================================================================+
DECLARE
  ln_request_id         NUMBER         DEFAULT &REQUEST_ID;
  
  CURSOR c_deposits IS
    SELECT xold.orig_sys_document_ref,
           xold.cash_receipt_id,
           xold.process_code,
           acr.receipt_number,
           acrh.status,
           arm.name receipt_method
      FROM xx_om_legacy_deposits xold, 
           ar_cash_receipts_all acr,
           ar_cash_receipt_history_all acrh,
           ar_receipt_methods arm
     WHERE xold.cash_receipt_id = acr.cash_receipt_id
       AND acr.cash_receipt_id = acrh.cash_receipt_id
       AND xold.receipt_method_id = arm.receipt_method_id
       AND acr.type = 'CASH'
       AND arm.name LIKE '%_CC OD ALL_CC'
       AND acrh.current_record_flag = 'Y'
       AND xold.request_id = ln_request_id
     ORDER BY orig_sys_document_ref;
     
  TYPE t_deposits IS TABLE OF c_deposits%ROWTYPE
    INDEX BY PLS_INTEGER;
    
  a_deposits       t_deposits;
BEGIN
  DBMS_OUTPUT.put_line( '=== Delete Settlement Trxs for Open Deposit Receipts at Go-Live ===' );  
  DBMS_OUTPUT.put_line( 'Request Id = ' || ln_request_id );  
  DBMS_OUTPUT.put_line( ' ' );
  
  OPEN c_deposits;
  FETCH c_deposits
   BULK COLLECT
   INTO a_deposits;
  CLOSE c_deposits;
  
  DBMS_OUTPUT.put_line( 'Found ' || a_deposits.COUNT || ' deposit receipts for request_id = ' || ln_request_id || '.' );
  DBMS_OUTPUT.put_line( ' ' );
  
  IF (a_deposits.COUNT > 0) THEN
    FOR i_index IN a_deposits.FIRST..a_deposits.LAST LOOP
      DBMS_OUTPUT.put_line( '== record ' || i_index || ' ==' );
      DBMS_OUTPUT.put_line( '  AOPS Order   : ' || a_deposits(i_index).orig_sys_document_ref );
      DBMS_OUTPUT.put_line( '  Rcpt Number  : ' || a_deposits(i_index).receipt_number );
      DBMS_OUTPUT.put_line( '  Rcpt Status  : ' || a_deposits(i_index).status );
      DBMS_OUTPUT.put_line( '  Process Code : ' || a_deposits(i_index).process_code );
      
      IF (a_deposits(i_index).status = 'REMITTED') THEN
        DELETE FROM XX_IBY_BATCH_TRXNS
         WHERE ixreceiptnumber LIKE a_deposits(i_index).receipt_number || '#%';
        
        DBMS_OUTPUT.put_line( 'Deleted ' || SQL%ROWCOUNT || ' rows from XX_IBY_BATCH_TRXNS.' );
        
        DELETE FROM XX_IBY_BATCH_TRXNS_DET
         WHERE ixreceiptnumber LIKE a_deposits(i_index).receipt_number || '#%';
        
        DBMS_OUTPUT.put_line( 'Deleted ' || SQL%ROWCOUNT || ' rows from XX_IBY_BATCH_TRXNS_DET.' );
      ELSE
        DBMS_OUTPUT.put_line( '**ERROR** - Receipt has not been Remitted.' );
      END IF;
      
      DBMS_OUTPUT.put_line( ' ' );
    END LOOP;
  END IF;
  
  COMMIT;
END;
/