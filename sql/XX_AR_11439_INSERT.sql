REM	_____________________________________________________________________
REM
REM     TITLE                   :  XX_AR_11439_INSERT.sql
REM     USED BY APPLICATION     :  AR  SDR Project
REM     PURPOSE                 :  Insert records into XX_AR_ORDER_RECEIPT_DTL for defect
REM     LIMITATIONS             :
REM     CREATED BY              :  Peter Marco, Lead Developer - EBS, Office Depot
REM     INPUTS                  :
REM     OUTPUTS                 :
REM     HISTORY                 :  WHO -        WHAT -          DATE -
REM     NOTES                   :
REM     ______________________________________________________________________


set serveroutput on;
ACCEPT p_date DATE PROMPT 'Enter Creation Date (DD-MON-YYYY)';

DECLARE 

ld_creation_date DATE := '&&p_date';
lc_count NUMBER;

BEGIN

  dbms_output.put_line ('Creation Date ='||ld_creation_date);
  
  SELECT count(1) 
    INTO lc_count 
       FROM    ar_cash_receipt_history CRH ,
               ar_cash_receipts_all ACRA   ,
               ar_receipt_methods RM       ,
               ar_receipt_classes RCLASS   ,
               hz_cust_accounts HCA        ,
               hz_parties HP               ,
               iby_trxn_summaries_all ITSA ,
               iby_trxn_core ITC           
       WHERE   CRH.cash_receipt_id                     = ACRA.cash_receipt_id
       AND     RM.receipt_method_id                    = ACRA.receipt_method_id
       AND     RCLASS.receipt_class_id                 = RM.receipt_class_id
       AND     ACRA.selected_remittance_batch_id IS NULL
       AND     CRH.status                              = 'CONFIRMED'
       AND     CRH.current_record_flag                 = 'Y'
       AND     RCLASS.remit_method_code                = 'STANDARD'
       AND     RM.payment_type_code                    ='CREDIT_CARD'
       AND     ITSA.tangibleid(+)                      = ACRA.payment_server_order_num
       AND     ITSA.trxnmid                            = ITC.trxnmid
       AND     ACRA.creation_date                      <= trunc(ld_creation_date) -- '12-MAY-2011'
       AND     ACRA.pay_from_customer                  = HCA.cust_account_id
       AND     HCA.party_id                            = HP.party_id
       AND     NOT EXISTS
               (SELECT /*+ index_ffs(r XX_AR_ORDER_RECEIPT_DTL_N7) */ 1 --*
               FROM    apps.xx_ar_order_receipt_dtl r
               WHERE   r.cash_receipt_id = ACRA.cash_receipt_id
               );
               
   IF   lc_count = 0 THEN
   
       dbms_output.put_line ('No Data Found!');  
   ELSE    
       dbms_output.put_line ('Rows to be Inserted:'|| lc_count ); 
       
   END IF;
   

INSERT  INTO   XX_AR_ORDER_RECEIPT_DTL
       (
              additional_auth_codes       ,
              allied_ind                  ,
              cash_receipt_id             ,
              cc_auth_manual              ,
              cc_auth_ps2000              ,
              cc_mask_number              ,
              check_number                ,
              created_by                  ,
              creation_date               ,
              credit_card_approval_code   ,
              credit_card_approval_date   ,
              credit_card_code            ,
              credit_card_expiration_date ,
              credit_card_holder_name     ,
              credit_card_number          ,
              customer_id                 ,
              customer_receipt_reference  ,
              customer_site_billto_id     ,
              header_id                   ,
              imp_file_name               ,
              last_update_date            ,
              last_updated_by             ,
              matched                     ,
              merchant_number             ,
              od_payment_type             ,
              order_number                ,
              order_payment_id      ,
              order_source          ,
              order_type            ,
              org_id                ,
              orig_sys_document_ref ,
              orig_sys_payment_ref  ,
              payment_amount        ,
              payment_number        ,
              payment_set_id        ,
              payment_type_code     ,
              process_code          ,
              process_date          ,
              receipt_date          ,
              receipt_method_id     ,
              receipt_number        ,
              receipt_status        ,
              remitted              ,
              request_id            ,
              sale_type             ,
              ship_from             ,
              store_number
       )
       (       
       SELECT  /*+ ORDERED index(hca HZ_CUST_ACCOUNTS_U1) */ ACRA.payment_server_order_num ,
               NULL                          ,
               ACRA.cash_receipt_id          ,
               NULL                          ,
               NULL                          ,
               NULL                          ,
               NULL                          ,
               -1                                 --CREATED_BY
               ,
               SYSDATE                            --CREATION_DATE
               ,
               ACRA.approval_code              ,
               TRUNC(ACRA.receipt_date)        ,
               ITSA.instrsubtype               ,
               ITC.instr_expirydate            ,
               HP.party_name                   ,
               ITSA.instrnumber                ,
               HCA.cust_account_id             ,
               ACRA.customer_receipt_reference ,
               NULL                            ,
               NULL                            ,
               NULL                            ,
               SYSDATE                          --LAST_UPDATE_DATE
               ,
               -1                               --LAST_UPDATED_BY
               ,
               'N'  ,
               NULL ,
               NULL ,
               NULL ,
               xx_ar_order_payment_id_s.NEXTVAL            ,
               NULL                                        ,
               NULL                                        ,
               ACRA.org_id                                 ,
               NULL                                        ,
               NULL                                        ,
               ACRA.amount                                 ,
               NULL                                        ,
               NULL                                        ,
               'CREDIT_CARD'                               ,
               'REMITTANCE'                                ,
               TRUNC(ACRA.receipt_date)                    ,
               TRUNC(ACRA.receipt_date)                    ,
               ACRA.receipt_method_id                      ,
               ACRA.receipt_number                         ,
               'OPEN'                                      ,
               'N'                                         ,
               NULL                                        ,
               DECODE(SIGN(ACRA.amount),-1,'REFUND',1,'SALE',NULL) ,
               NULL                                        ,
               NULL
       FROM    ar_cash_receipt_history CRH ,
               ar_cash_receipts_all ACRA   ,
               ar_receipt_methods RM       ,
               ar_receipt_classes RCLASS   ,
               hz_cust_accounts HCA        ,
               hz_parties HP               ,
               iby_trxn_summaries_all ITSA ,
               iby_trxn_core ITC           
       WHERE   CRH.cash_receipt_id                     = ACRA.cash_receipt_id
         AND     RM.receipt_method_id                    = ACRA.receipt_method_id
         AND     RCLASS.receipt_class_id                 = RM.receipt_class_id
         AND     ACRA.selected_remittance_batch_id IS NULL
         AND     CRH.status                              = 'CONFIRMED'
         AND     CRH.current_record_flag                 = 'Y'
         AND     RCLASS.remit_method_code                = 'STANDARD'
         AND     RM.payment_type_code                    ='CREDIT_CARD'
         AND     ITSA.tangibleid(+)                      = ACRA.payment_server_order_num
         AND     ITSA.trxnmid                            = ITC.trxnmid
         AND     ACRA.creation_date                      < trunc(ld_creation_date)  --'12-MAY-2011'
         AND     ACRA.pay_from_customer                  = HCA.cust_account_id
         AND     HCA.party_id                            = HP.party_id );                  
   
   
   
       dbms_output.put_line ('Rows Inserted:'||  SQL%ROWCOUNT );   
   
EXCEPTION
   WHEN OTHERS THEN
      dbms_output.put_line ('ERROR:'||SUBSTR(SQLERRM,1,249));
   
END;


