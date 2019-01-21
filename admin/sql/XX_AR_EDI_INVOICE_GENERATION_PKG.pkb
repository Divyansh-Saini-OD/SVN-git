create or replace 
PACKAGE BODY XX_AR_EDI_INV_GENERATION_PKG
AS
  -- +=============================================================================+
  -- |  Office Depot                                                               |
  -- +=============================================================================+
  -- |  Name:  XX_AR_EDI_INV_GENERATION_PKG                                        |
  -- |                                                                             |
  -- |  Description:  This package is to launch EDI Invoice Generation program     |
  -- |                                                                             |
  -- |  Change Record:                                                             |
  -- +=============================================================================+
  -- | Version     Date         Author              Remarks                        |
  -- | =========   ===========  =============       ===============================|
  -- | 1.0         20-JUN-2017  JAI_CG              Initial version                |
  -- +=============================================================================+
  
  PROCEDURE submit_inv_genration(errbuff       OUT VARCHAR2,
                                 retcode       OUT VARCHAR2,
                                 p_send_inv_edi IN VARCHAR2)
  IS

  -- Cursor to fetch EDI customers from translation  
  CURSOR cur_edi_customers
  IS

    SELECT hca.cust_account_id,
           vals.target_value1 account_name,
           vals.target_value2 account_nnumber
    FROM   xx_fin_translatedefinition defn,
           xx_fin_translatevalues vals,
           hz_cust_accounts hca
    WHERE  defn.translation_name = 'XX_AR_EDI_CUSTOMERS'
    AND    SYSDATE BETWEEN defn.start_date_active AND NVL(defn.end_date_active, SYSDATE + 1)
    AND    defn.enabled_flag   = 'Y'
    AND    defn.translate_id   = vals.translate_id
    AND    SYSDATE BETWEEN vals.start_date_active AND NVL(vals.end_date_active, SYSDATE + 1)
    AND    vals.enabled_flag   = 'Y'
    AND    hca.account_number  = vals.target_value2;

  -- Variable declaration
  lv_cust_accounts VARCHAR2 (2000) := NULL;

  ln_cur_count NUMBER := 0;
  
  lc_short_name_in  VARCHAR2(10)   := 'XXFIN';
  
  lc_program_in     VARCHAR2(100)  := 'XXARINVINFOCOPYEDI';
  
  lc_description_in VARCHAR2(100)  := 'OD: AR Info Copy EDI Invoice Generation';
  
  ln_request_id     NUMBER;

  BEGIN

    FND_FILE.PUT_LINE(FND_FILE.LOG, '***************************************');
    FND_FILE.PUT_LINE(FND_FILE.LOG, 'Starting submit_inv_genration routine. ');
    FND_FILE.PUT_LINE(FND_FILE.LOG, '***************************************');
    
    ln_cur_count := 0;
      
    -- Loop to fetch list of customers
    FOR edi_customers_rec IN cur_edi_customers
    LOOP  
      
      -- Submitting the EDI Invoice Generation program
      BEGIN
      
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'Submitting program: ' || lc_description_in || ' for customer: ' || edi_customers_rec.cust_account_id);
        
        ln_request_id := fnd_request.submit_request(application => lc_short_name_in,
                                                    program     => lc_program_in,
                                                    description => lc_description_in,
                                                    start_time  => TO_CHAR(SYSDATE,'YYYY-MM-DD HH24:MI:SS'),
                                                    sub_request => FALSE,
                                                    argument1   => edi_customers_rec.cust_account_id,
                                                    argument2   => p_send_inv_edi
                                                   );

        COMMIT;

        IF ln_request_id = 0 
        THEN

          FND_FILE.PUT_LINE(FND_FILE.LOG, 'Program :' || lc_description_in || 'for customer: ' || 
                                           edi_customers_rec.cust_account_id || ' failed to get submitted');

          errbuff := 'Conc. Program  failed to submit :' || lc_description_in;
          
          retcode := 2; -- Terminate the program

        ELSE

          FND_FILE.PUT_LINE(FND_FILE.LOG, 'Program :' || lc_description_in || 'for customer: ' || 
                                           edi_customers_rec.cust_account_id || ' submitted with request id: ' || ln_request_id);

        END IF;

      EXCEPTION
        WHEN OTHERS 
        THEN
        
          errbuff := 'Exception while Submit Program :' || '-' || SQLERRM;
          
          FND_FILE.PUT_LINE(FND_FILE.LOG, errbuff);
          
          retcode := 2; -- Terminate the program
      END;
    
    END LOOP; -- Ending edi_customers_rec

  EXCEPTION 
    WHEN OTHERS 
    THEN
         
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'No valid customers available for processing ' || SQLERRM);

  END submit_inv_genration;
  
END XX_AR_EDI_INV_GENERATION_PKG;
/
SHOW ERRORS;
EXIT;