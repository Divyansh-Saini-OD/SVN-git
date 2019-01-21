create or replace PACKAGE BODY XX_FIN_VPS_RECEIPT_UPLOAD_PKG
AS
  -- +============================================================================================+
  -- |  Office Depot                                                                              |
  -- +============================================================================================+
  -- |  Name:  XX_FIN_VPS_RECEIPT_UPLOAD_PKG                                                      |
  -- |                                                                                            |
  -- |  Description:  This package is used by WEB ADI to load VPS Manual Receipts.                |
  -- |                                                                                            |
  -- |  Change Record:                                                                            |
  -- +============================================================================================+
  -- | Version     Date         Author           Remarks                                          |
  -- | =========   ===========  =============    ===============================================  |
  -- | 1.0         07-AUG-2017  Thejaswini Rajula    Initial version                              |
  -- +============================================================================================+
PROCEDURE INSERT_VPS_RECEIPT_UPLOAD(P_VENDOR_NUM     IN VARCHAR2 ,
                                    P_RECEIPT_NUMBER IN VARCHAR2 ,
                                    P_RECEIPT_DATE   IN VARCHAR2 ,
                                    P_RECEIPT_METHOD IN VARCHAR2 ,
                                    P_RECEIPT_AMOUNT IN NUMBER ,
                                    P_INVOICE_NUMBER IN VARCHAR2 ,
                                    P_INVOICE_AMOUNT IN NUMBER )
IS
l_error_message                    VARCHAR2(3000);
l_error_code                       VARCHAR2(3000);
l_cust_account_id                  NUMBER;
l_receipt_date                     VARCHAR2(150);
l_trx_number                       ra_customer_trx_all.trx_number%TYPE;
x_vendor_num                       EXCEPTION;
x_receipt_date                     EXCEPTION;
x_vendor_num_others                EXCEPTION;
x_receipt_date_others              EXCEPTION;

BEGIN              
 --Vendor Num Validation  
          BEGIN
                  SELECT hca.cust_account_id
                    INTO l_cust_account_id
                    FROM hz_cust_accounts_all hca
                   WHERE 1                  =1
                      AND hca.orig_system_reference=p_vendor_num||'-VPS';                    
                  EXCEPTION
                        WHEN no_data_found THEN
                            l_error_message :=l_error_message
                                               ||','||
                                               'Please enter a vendor number that already exist in the system.';
                             l_error_code    := 'E';
                             --RAISE x_vendor_num;
                       WHEN OTHERS THEN
                           -- RAISE x_vendor_num_others;
                             l_error_message :=l_error_message
                                               ||','||
                                               'Please enter a vendor number that already exist in the system.';
                             l_error_code    := 'E';
                             --raise_application_error(-20101,l_error_message); 
          END;
  --Receipt Number Validation  
    IF P_RECEIPT_NUMBER IS NULL THEN 
        l_error_message :=l_error_message
               ||','||
               'Please enter Receipt Number.';
               l_error_code    := 'E';
    
    END IF;
          
  --Receipt Date Validation 
  IF P_RECEIPT_DATE IS NULL THEN 
    l_error_message :=l_error_message
                      ||','||
                      'Please enter Valid Receipt Date format DD-MON-YYYY';
    l_error_code    := 'E';
  ELSE
          BEGIN
          
                  SELECT TO_DATE(P_RECEIPT_DATE,'DD-MON-YYYY')
                    INTO l_receipt_date
                    FROM DUAL;
                  EXCEPTION
                        WHEN no_data_found THEN
                           l_error_message :=l_error_message
                                                         ||','||
                                                         'Please enter Valid Receipt Date format DD-MON-YYYY';
                                       l_error_code    := 'E';
                          --  RAISE x_receipt_date;
                        WHEN OTHERS THEN 
                          --  RAISE x_receipt_date_others;
                          l_error_message :=l_error_message
                                                         ||','||
                                                         'Please enter Valid Receipt Date format DD-MON-YYYY';
                                       l_error_code    := 'E';
                                    --  raise_application_error(-20101,l_error_message);
          END;
    END IF;
      --Receipt Amount Validation  
    IF (P_RECEIPT_AMOUNT IS NULL OR P_RECEIPT_AMOUNT=0) THEN 
        l_error_message :=l_error_message
               ||','||
               'Please enter Receipt Amount.';
               l_error_code    := 'E';
    
    END IF;
  --Invoice Number Validation  
 /* IF P_INVOICE_NUMBER IS NOT NULL THEN 
          BEGIN
               SELECT rct.trx_number
                INTO l_trx_number
                FROM ra_customer_trx_all rct,
                     ar_payment_schedules_all arp
                WHERE 1=1
                  AND rct.trx_number=P_INVOICE_NUMBER
                  AND rct.customer_trx_id=arp.customer_trx_id
                  AND arp.status='CL';                
            EXCEPTION
                WHEN no_data_found THEN
                    NULL;
                 WHEN OTHERS THEN
                             l_error_message :=l_error_message
                                               ||','||
                                               'Please enter a valid Invoice Number.';
                             l_error_code    := 'E'; 
          END;
        IF l_trx_number IS NOT NULL THEN 
           l_error_message :=l_error_message
                 ||','||
                 'Invoice is Closed. Please enter a valid Invoice Number.';
                 l_error_code    := 'E';
          ELSE
            l_trx_number:=P_INVOICE_NUMBER;
        END IF;
  ELSE
    l_trx_number:=P_INVOICE_NUMBER;
  END IF; */
  IF l_error_code='E' THEN 
    raise_application_error(-20101,l_error_message);
  ELSE
   INSERT
  INTO XX_FIN_VPS_RECEIPTS_STG
    (
      VENDOR_NUM ,
      RECEIPT_NUMBER ,
      RECEIPT_DATE ,
      RECEIPT_METHOD ,
      RECEIPT_AMOUNT ,
      INVOICE_NUMBER ,
      INVOICE_AMOUNT ,
      INTERFACE_ID ,
      REQUEST_ID ,
      RECORD_STATUS ,
      ERROR_MESSAGE ,
      VALIDATE_PROCESS_DATA ,
      EMAIL_FLAG,
      LAST_UPDATE_DATE ,
      LAST_UPDATED_BY ,
      CREATION_DATE ,
      CREATED_BY
    )
    VALUES
    ( P_VENDOR_NUM ,
      P_RECEIPT_NUMBER ,
      l_receipt_date ,
      P_RECEIPT_METHOD ,
      ROUND(P_RECEIPT_AMOUNT,2) ,
      P_INVOICE_NUMBER ,
      ROUND(P_INVOICE_AMOUNT,2) ,
      XX_FIN_VPS_RECEIPTS_STG_S.nextval,
      NULL ,
      'N' ,
      NULL ,
      NULL,
      'N',
      SYSDATE ,
      fnd_global.user_id ,
      SYSDATE ,
      fnd_global.user_id
    );
--COMMIT;
END IF;
--EXCEPTION
--WHEN OTHERS THEN
-- FND_FILE.PUT_LINE(FND_FILE.LOG,'Unexpected error inserting into staging table'||SUBSTR(sqlerrm,1,200));
--  FND_FILE.PUT_LINE(FND_FILE.LOG,'');
  --raise_application_error(-20102,l_error_message);
END INSERT_VPS_RECEIPT_UPLOAD;
END XX_FIN_VPS_RECEIPT_UPLOAD_PKG;
/