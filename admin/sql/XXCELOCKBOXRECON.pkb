CREATE OR REPLACE PACKAGE BODY XX_CE_LOCKBOX_RECON_PKG AS 
-- +=================================================================================+
-- |                       Office Depot - Project Simplify                           |
-- |                            Providge Consulting                                  |
-- +=================================================================================+
-- | Name       : XXCELOCKBOXRECON.pkb                                               |
-- | Description: Cash Management Lockbox Reconciliation E1297-Extension             |
-- |                                                                                 |
-- |                                                                                 |
-- |                                                                                 |
-- |                                                                                 |
-- |Change Record                                                                    |
-- |==============                                                                   |
-- |Version   Date         Authors            Remarks                                |
-- |========  ===========  ===============    ============================           |
-- |DRAFT 1A  10-JUL-2007  Sunayan Mohanty    Initial draft version                  |
-- |1.0       03-AUG-2007  Sunayan Mohanty    Incorporated all the review comments   |
-- |          24-SEP-2007  Terry Banks        Set to read only trx_code 115 CSL rows |
-- |          16-OCT-2007  Sunayan Mohanty    Added the trx Code'001' Validation     |
-- |                                                                                 |
-- |          23-OCT-2007  Sunayan Mohanty    Use Lockbox Number to find out the Batch Amount |
-- |                                          from AR_Batches for all close transmission|
-- |                                          Remove the GL entry for any difference in amount |
-- |                                          Bank of America and 5/3rd Bank are going to |  
-- |                                          provide lockbox number in invoice text column|
-- |                                          Added Email id p_email_id as parameter to use     |
-- |          24-OCT-2007  Sunayan Mohanty    Added Bank Account in Output Report    |
-- |          06-NOV-2007  Sunayan Mohanty    Changed p_from_date and p_to_date are non - mandatory|
-- |                                          Changed the matching of bank deposit and in CE statement lines for sum of same lockbox number|
-- |          02-FEB-2008  Terry Banks        Changed ajb_file_number to bank_rec_id |
-- |                                          to allow for table changes.            |
-- +=================================================================================+

  -- -------------------------------------------
  -- Global Variables
  -- -------------------------------------------
  gn_request_id               NUMBER        :=  FND_GLOBAL.CONC_REQUEST_ID;
  gn_user_id                  NUMBER        :=  FND_GLOBAL.USER_ID;
  gn_login_id                 NUMBER        :=  FND_GLOBAL.LOGIN_ID;
  gn_org_id                   NUMBER        :=  FND_PROFILE.VALUE('ORG_ID');
  gn_set_of_bks_id            NUMBER        :=  FND_PROFILE.VALUE('GL_SET_OF_BKS_ID');
  gc_conc_short_name          VARCHAR2(30)  :=  'XXCELOCKBOXRECON';  
  gn_error                    NUMBER        :=  2;
  gn_warning                  NUMBER        :=  1;
  gn_normal                   NUMBER        :=  0;

-- +=================================================================================+
-- | Name        : PRINT_MESSAGE_HEADER                                              |
-- | Description : This procedure will be used to print the                          |
-- |               record process details                                            |
-- |                                                                                 |
-- | Parameters  : None                                                              |
-- |                                                                                 |
-- |                                                                                 |
-- | Returns     : x_errbuf                                                          |
-- |               x_retcode                                                         |
-- |                                                                                 |
-- +=================================================================================+
PROCEDURE print_message_header
                          (x_errbuf           OUT   NOCOPY  VARCHAR2
                          ,x_retcode          OUT   NOCOPY  NUMBER
                          )
IS


BEGIN 
  
  -- ------------------------------------------------
  -- Set the Concurrent program Output header display
  -- ------------------------------------------------
  FND_FILE.NEW_LINE(FND_FILE.OUTPUT,1);
  FND_FILE.NEW_LINE(FND_FILE.OUTPUT,1);

  FND_FILE.PUT_LINE(FND_FILE.OUTPUT, RPAD('=',50,'=')||'   Cash Management Lockbox Recon    '||RPAD('=',50,'='));
  FND_FILE.NEW_LINE(FND_FILE.OUTPUT,1);      
  
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT, LPAD('Lockbox Reconciliation Extension',76,' '));
  FND_FILE.NEW_LINE(FND_FILE.OUTPUT,1);
  
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'Request ID : '||gn_request_id||RPAD(' ',60,' ')||'Request Date : '||TO_CHAR(SYSDATE,'DD-MON-YYYY HH:MM:SS'));  
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT, RPAD('=',125,'='));   
  
  FND_FILE.NEW_LINE(FND_FILE.OUTPUT,1);  
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT, RPAD('Bank Account ',23)||RPAD('Statement/Line ',23)||RPAD('Statement Date',17)||'Description');
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT, RPAD('-',(20-1),'-')||'    '||RPAD('-',(20-1),'-')||'    '||RPAD('-',(12-1),'-')||'      '||RPAD('-',(25-1),'-')||''||RPAD('-',(120-60),'-'));   

EXCEPTION 
WHEN OTHERS THEN 
  fnd_message.set_name ('XXFIN','XX_CE_001_UNEXPECTED');  
  fnd_message.set_token('PACKAGE','XX_CE_LOCKBOX_RECON_PKG.print_message_header');
  fnd_message.set_token('PROGRAM','CE Lockbox Reconciliation Extension');
  fnd_message.set_token('SQLERROR',SQLERRM);
  x_errbuf   := fnd_message.get;  
  x_retcode  := gn_error;
  FND_FILE.PUT_LINE(FND_FILE.LOG,'==========================');
  FND_FILE.PUT_LINE(FND_FILE.LOG,x_errbuf);   
END print_message_header;  

-- +=================================================================================+
-- |                                                                                 |
-- | PROCEDURE                                                                       |
-- |   print_message_footer                                                          |
-- |                                                                                 |
-- | DESCRIPTION                                                                     |
-- |  Procedure to Print the Message Details                                         |
-- |                                                                                 |
-- | PARAMETERS                                                                      |
-- | ==========                                                                      |
-- | NAME                    TYPE    DESCRIPTION                                     |
-- | ----------------------- ------- ----------------------------------------        |
-- | x_errbuf                 OUT     Error message.                                 |
-- | x_retcode                OUT     Error code.                                    |
-- | p_message                IN      Message Details                                |
-- |                                                                                 |
-- |                                                                                 |
-- | PREREQUISITES                                                                   |
-- |   None.                                                                         |
-- |                                                                                 |
-- | CALLED BY                                                                       |
-- |   recon_process                                                                 |
-- |                                                                                 |
-- +=================================================================================+
PROCEDURE print_message_footer 
                         (x_errbuf               OUT NOCOPY VARCHAR2
                         ,x_retcode              OUT NOCOPY NUMBER
                         ,p_statement_number     IN         VARCHAR2
                         ,p_lockbox_batch        IN         VARCHAR2
                         ,p_bank_act_num         IN         VARCHAR2
                         ,p_stmt_date            IN         DATE
                         ,p_message              IN         VARCHAR2
                         )
IS

BEGIN
  
  IF p_message IS NULL THEN     
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,RPAD(NVL(p_bank_act_num,''),20)||'  '||LPAD(NVL(p_statement_number,''),16)||'       '||LPAD(NVL(p_stmt_date,''),10)||'                 '||REPLACE(p_message,CHR(10),CHR(10)||LPAD(' ',(40),' ')));
  ELSE    
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,RPAD(NVL(p_bank_act_num,''),20)||'  '||LPAD(NVL(p_statement_number,''),16)||'       '||LPAD(NVL(p_stmt_date,''),10)||'           '||REPLACE(p_message,CHR(10),CHR(10)||LPAD(' ',(40),' ')));
  END IF;
  
EXCEPTION 
WHEN OTHERS THEN 
  fnd_message.set_name ('XXFIN','XX_CE_001_UNEXPECTED');  
  fnd_message.set_token('PACKAGE','XX_CE_LOCKBOX_RECON_PKG.print_message_footer');
  fnd_message.set_token('PROGRAM','CE Lockbox Reconciliation Extension');
  fnd_message.set_token('SQLERROR',SQLERRM);
  x_errbuf   := fnd_message.get;  
  x_retcode  := gn_error;
  FND_FILE.PUT_LINE(FND_FILE.LOG,'==========================');
  FND_FILE.PUT_LINE(FND_FILE.LOG,x_errbuf);   
END print_message_footer;

-- +=================================================================================+
-- |                                                                                 |
-- |PROCEDURE                                                                        |
-- |  print_message_summary                                                          |
-- |                                                                                 |
-- |DESCRIPTION                                                                      |
-- | Procedure to Print Summary of the Record Process                                |
-- |                                                                                 |
-- |PARAMETERS                                                                       |
-- |==========                                                                       |
-- |NAME                    TYPE    DESCRIPTION                                      |
-- |----------------------- ------- ----------------------------------------         |
-- |x_errbuf                 OUT     Error message.                                  |
-- |x_retcode                OUT     Error code.                                     |
-- |p_total                  IN      Total Records Found                             |
-- |p_error                  IN      Error Records                                   |
-- |p_success                IN      Success Records                                 |
-- |                                                                                 |
-- |PREREQUISITES                                                                    |
-- |  None.                                                                          |
-- |                                                                                 |
-- |CALLED BY                                                                        |
-- |  recon_process                                                                  |
-- +=================================================================================+ 
PROCEDURE print_message_summary
                           (x_errbuf               OUT NOCOPY VARCHAR2
                           ,x_retcode              OUT NOCOPY NUMBER
                           ,p_total                IN         NUMBER
                           ,p_error                IN         NUMBER
                           ,p_success              IN         NUMBER                                
                           )
IS

BEGIN


  IF p_total > 0 THEN
    -------------------------------------------------------------------------------------------------
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, RPAD('=',50,'=')||'   End Process Details    '||RPAD('=',45,'='));
    -------------------------------------------------------------------------------------------------
      
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'===============================================================');
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'CE Lockbox Reconciliation Extension : '||'E1297');
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'===============================================================');
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Total Record Found               : '||NVL(p_total,0));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Error Record                     : '||NVL(p_error,0));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Success Records                  : '||NVL(p_success,0));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'===============================================================');  
  ELSE  
    -------------------------------------------------------------------------------------------------------------
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, RPAD('-',50,'-')||'  No Record Found for Processing   '||RPAD('-',45,'-'));
    -------------------------------------------------------------------------------------------------------------
  END IF;
    
EXCEPTION 
WHEN OTHERS THEN 
  fnd_message.set_name ('XXFIN','XX_CE_001_UNEXPECTED');  
  fnd_message.set_token('PACKAGE','XX_CE_LOCKBOX_RECON_PKG.print_message_summary');
  fnd_message.set_token('PROGRAM','CE Lockbox Reconciliation');
  fnd_message.set_token('SQLERROR',SQLERRM);
  x_errbuf   := fnd_message.get;  
  x_retcode  := gn_error;
  FND_FILE.PUT_LINE(FND_FILE.LOG,'==========================');
  FND_FILE.PUT_LINE(FND_FILE.LOG,x_errbuf);   
END print_message_summary;

-- +=================================================================================+
-- |                                                                                 |
-- |PROCEDURE                                                                        |
-- |  create_open_interface                                                          |
-- |                                                                                 |
-- |DESCRIPTION                                                                      |
-- | This procedure will be used to create the                                       |
-- | record into xx_ce_999_interface table for reconcilaition                        |
-- |                                                                                 |
-- |PARAMETERS                                                                       |
-- |==========                                                                       |
-- |NAME                    TYPE    DESCRIPTION                                      |
-- |----------------------- ------- ----------------------------------------         |
-- |x_errbuf                 OUT     Error message.                                  |
-- |x_retcode                OUT     Error code.                                     |
-- |p_trx_code_id            IN      Trnsaction Code ID                              |
-- |p_bank_account_id        IN      Bank Account ID                                 |
-- |p_bank_trx_number_org    IN      Bank Transaction Number Original                |  
-- |p_trx_date               IN      Transaction Date                                |
-- |p_currency_code          IN      Currency Code                                   |
-- |p_amount                 IN      Amount                                          |
-- |p_statement_header_id    IN      Statement Header ID                             |
-- |p_statement_line_id      IN      Statement Line ID                               |
-- |p_provider_code          IN      Provider Code                                   |
-- |p_receipt_method_id      IN      Receipt Method ID                               |
-- |p_lockbox_batch          IN      Lockbox Batch                                   |
-- |p_lockbox_deposit_date   IN      Lockbox Deposit Date                            |
-- |p_ajb_bank_rec_id        IN      AJB File Ref Number                             |
-- |                                                                                 |
-- |PREREQUISITES                                                                    |
-- |  None.                                                                          |
-- |                                                                                 |
-- |CALLED BY                                                                        |
-- |  recon_process                                                                  |
-- +=================================================================================+ 
PROCEDURE create_open_interface
                          ( x_errbuf                    OUT   NOCOPY  VARCHAR2
                          , x_retcode                   OUT   NOCOPY  NUMBER
                          , x_interface_seq             OUT   NOCOPY  NUMBER
                          , p_trx_code_id               IN            NUMBER
                          , p_bank_account_id           IN            NUMBER
                          , p_bank_trx_number_org       IN            VARCHAR2
                          , p_trx_date                  IN            DATE
                          , p_currency_code             IN            VARCHAR2  
                          , p_amount                    IN            NUMBER
                          , p_statement_header_id       IN            NUMBER
                          , p_statement_line_id         IN            NUMBER
                          , p_provider_code             IN            VARCHAR2
                          , p_receipt_method_id         IN            NUMBER     DEFAULT NULL
                          , p_lockbox_batch             IN            VARCHAR2   DEFAULT NULL
                          , p_lockbox_deposit_date      IN            DATE    
                          , p_ajb_bank_rec_id           IN            VARCHAR2                          
                          )
IS

ln_ce_interface_seq        NUMBER;

BEGIN 
   -- ------------------------------------------------
   -- Get the Nexval Value
   -- ------------------------------------------------
   SELECT xx_ce_999_interface_s.nextval
   INTO   ln_ce_interface_seq 
   FROM   DUAL;
   
  -- ------------------------------------------------
  -- Insert the record into xx_ce_999_interface table
  -- ------------------------------------------------
  INSERT INTO xx_ce_999_interface (  trx_id
                                   , bank_trx_code_id_original
                                   , bank_account_id         
                                   , trx_type                
                                   , trx_type_dsp            
                                   , trx_number              
                                   , trx_date                
                                   , currency_code           
                                   , status                  
                                   , amount                  
                                   , record_type             
                                   , bank_trx_number_original
                                   , lockbox_deposit_date    
                                   , lockbox_batch           
                                   , receipt_method_id       
                                   , statement_header_id     
                                   , statement_line_id       
                                   , creation_date           
                                   , created_by              
                                   , last_update_date        
                                   , last_updated_by         
                                   , bank_rec_id         
                                  ) 
                        VALUES    (  ln_ce_interface_seq
                                   , p_trx_code_id
                                   , p_bank_account_id
                                   , 'CASH'
                                   , NULL
                                   , ln_ce_interface_seq
                                   , p_trx_date
                                   , p_currency_code
                                   , 'FLOAT'
                                   , p_amount
                                   , p_provider_code
                                   , p_bank_trx_number_org
                                   , p_lockbox_deposit_date
                                   , p_lockbox_batch
                                   , p_receipt_method_id
                                   , p_statement_header_id
                                   , p_statement_line_id
                                   , SYSDATE
                                   , gn_user_id
                                   , SYSDATE
                                   , gn_user_id
                                   , p_ajb_bank_rec_id
                                   );
                                   
  x_interface_seq  := ln_ce_interface_seq;
 
EXCEPTION 
WHEN OTHERS THEN 
  fnd_message.set_name ('XXFIN','XX_CE_001_UNEXPECTED');  
  fnd_message.set_token('PACKAGE','XX_CE_LOCKBOX_RECON_PKG.create_open_interface');
  fnd_message.set_token('PROGRAM','CE Lockbox Reconciliation Extension');
  fnd_message.set_token('SQLERROR',SQLERRM);
  x_errbuf   := fnd_message.get;  
  x_retcode  := gn_error;
  FND_FILE.PUT_LINE(FND_FILE.LOG,'==========================');
  FND_FILE.PUT_LINE(FND_FILE.LOG,x_errbuf);   
END create_open_interface;  

-- +=================================================================================+
-- |                                                                                 |
-- |PROCEDURE                                                                        |
-- |  update_stmt_rec                                                                |
-- |                                                                                 |
-- |DESCRIPTION                                                                      |
-- | This procedure will be used to update the                                       |
-- | status into CE Statement Header / Lines Tables after processing                 |
-- |                                                                                 |
-- |PARAMETERS                                                                       |
-- |==========                                                                       |
-- |NAME                    TYPE    DESCRIPTION                                      |
-- |----------------------- ------- ----------------------------------------         |
-- |x_errbuf                 OUT     Error message.                                  |
-- |x_retcode                OUT     Error code.                                     |
-- |p_bank_stmt_header       IN      Statement Header ID                             |
-- |p_bank_stmt_line         IN      Statement Line ID                               |
-- |                                                                                 |
-- |                                                                                 |
-- |PREREQUISITES                                                                    |
-- |  None.                                                                          |
-- |                                                                                 |
-- |CALLED BY                                                                        |
-- |  recon_process                                                                  |
-- +=================================================================================+ 
PROCEDURE update_stmt_rec
                          ( x_errbuf                    OUT   NOCOPY  VARCHAR2
                          , x_retcode                   OUT   NOCOPY  NUMBER
                          , p_bank_stmt_header          IN            NUMBER
                          , p_bank_stmt_line            IN            NUMBER
                          , p_bank_account_id           IN            NUMBER
                          , p_create_gl                 IN            VARCHAR2
                          , p_interface_seq             IN            NUMBER
                          , p_001_trx_code              IN            NUMBER DEFAULT NULL
                          )
IS


BEGIN 
  -- ------------------------------------------------
  -- Update the record into ce_statement_headers_all
  -- ce_statement_lines tables after processing the
  -- each line record
  -- ------------------------------------------------  
  UPDATE ce_statement_lines     CSL
  SET    CSL.attribute15          = DECODE(p_create_gl,'YES','PROCESSED-E1297','NO','PROCESSED-E1297','E','ERROR-E1297')
        ,CSL.bank_trx_number      = DECODE(p_create_gl,'YES',p_interface_seq,'NO',p_interface_seq,CSL.bank_trx_number)
        ,CSL.trx_code_id          = DECODE(p_create_gl,'YES',p_001_trx_code,'NO',p_001_trx_code,CSL.trx_code_id)
  WHERE  CSL.statement_header_id  = p_bank_stmt_header
  AND    CSL.statement_line_id    = p_bank_stmt_line;
  

EXCEPTION 
WHEN OTHERS THEN 
  fnd_message.set_name ('XXFIN','XX_CE_001_UNEXPECTED');  
  fnd_message.set_token('PACKAGE','XX_CE_LOCKBOX_RECON_PKG.update_stmt_rec');
  fnd_message.set_token('PROGRAM','CE Lockbox Reconciliation Extension');
  fnd_message.set_token('SQLERROR',SQLERRM);
  x_errbuf   := fnd_message.get;  
  x_retcode  := gn_error;
  FND_FILE.PUT_LINE(FND_FILE.LOG,'==========================');
  FND_FILE.PUT_LINE(FND_FILE.LOG,x_errbuf);   
END update_stmt_rec;  

-- +=================================================================================+
-- |                                                                                 |
-- |PROCEDURE                                                                        |
-- |  recon_process                                                                  |
-- |                                                                                 |
-- |DESCRIPTION                                                                      |
-- | Procedure to process the CE Bank Deposit and AR Receipts                        |
-- |                                                                                 |
-- |PARAMETERS                                                                       |
-- |==========                                                                       |
-- |NAME                    TYPE    DESCRIPTION                                      |
-- |----------------------- ------- ----------------------------------------         |
-- |x_errbuf                 OUT     Error message.                                  |
-- |x_retcode                OUT     Error code.                                     |
-- |                                                                                 |
-- |PREREQUISITES                                                                    |
-- |  None.                                                                          |
-- |                                                                                 |
-- |CALLED BY                                                                        |
-- |  Main Procedure                                                                 |
-- |                                                                                 |
-- +=================================================================================+ 
PROCEDURE  recon_process
                        (x_errbuf               OUT NOCOPY VARCHAR2
                        ,x_retcode              OUT NOCOPY NUMBER
                        ,p_run_from_date        IN         VARCHAR2
                        ,p_run_to_date          IN         VARCHAR2
                        ,p_email_id             IN         VARCHAR2     DEFAULT NULL
                        )
IS
  
  -- -------------------------------------------
  -- Get all the Lockbox  Bank Statement Lines
  -- from CE statement header and lines tables
  -- -------------------------------------------
  CURSOR lcu_bnk_stmt_hdr_line (  p_statement_header_id  IN NUMBER
                                , p_from_date            IN DATE
                                , p_to_date              IN DATE)  
  IS
  SELECT CSH.statement_header_id  
        ,CSH.bank_account_id
        ,CSH.statement_number
        ,CSH.statement_date
        ,NVL(CSH.currency_code,ABA.currency_code) currency_code
        ,CSL.attribute14
        ,CSL.attribute15
        ,CSL.statement_line_id
        ,CSL.line_number
        ,CSL.trx_date
        ,CSL.trx_type
        ,CSL.amount
        ,CSL.status
        ,CSL.trx_code_id
        ,CSL.effective_date
        ,CSL.bank_trx_number
        ,CSL.trx_text
        ,CSL.customer_text
        ,CSL.invoice_text
        ,CSL.bank_account_text
        ,CSL.reference_txt
        ,CSL.ce_statement_lines
        ,CSL.je_status_flag
        ,CSL.accounting_date
        ,CSL.gl_account_ccid
        ,ABA.bank_account_name
        ,ABA.bank_account_num
        ,ABA.bank_account_type
        ,ABA.inactive_date
  FROM   --ce_statement_headers_v    CSH
         ce_statement_headers      CSH 
        ,ce_statement_lines        CSL
        ,ap_bank_accounts          ABA
        ,ce_transaction_codes      CTC
  WHERE  CSH.statement_header_id    = p_statement_header_id
  AND    CSH.statement_header_id    = CSL.statement_header_id   
  AND    CSH.bank_account_id        = ABA.bank_account_id
  AND    CSL.TRX_CODE_ID            = CTC.TRANSACTION_CODE_ID(+)
  AND    CTC.trx_code               = '115'
  AND    CTC.BANK_ACCOUNT_ID        = ABA.bank_account_id
  AND    (CSL.status IS NULL 
       OR UPPER(CSL.status) = 'UNRECONCILED')
  AND    (CSL.attribute15 IS NULL 
       OR CSL.attribute15 NOT IN('PROCESSED-E1297'))
  AND    CSH.statement_date BETWEEN NVL(p_from_date,CSH.statement_date)  AND NVL(p_to_date,CSH.statement_date)
  AND    ABA.bank_account_type      = 'Corporate - Lockbox'
  AND    NVL(ABA.inactive_date,p_from_date) BETWEEN p_from_date AND p_to_date
  ORDER BY ABA.bank_account_num
          ,CSH.statement_number
          ,CSL.line_number ;
  
  -- ------------------------------------------- 
  -- Get all the Lockbox  Bank Statement Lines   
  -- from CE statement header and lines tables   
  -- ------------------------------------------- 
  CURSOR lcu_get_bank_ccid (  p_trx_code_id     IN ce.ce_transaction_codes.transaction_code_id%TYPE
                            , p_bank_account_id IN ap.ap_bank_accounts_all.bank_account_id%TYPE)
  IS
  SELECT ABA.bank_account_id
        ,ABA.bank_account_name
        ,ABA.bank_account_num
        ,ABA.bank_branch_id
        ,ABA.set_of_books_id
        ,ABA.currency_code
        ,ABA.description
        ,ABA.bank_account_type
        ,ABA.account_type
        ,ABA.org_id
        ,ABA.cash_clearing_ccid
        ,ABA.bank_charges_ccid
        ,ABA.bank_errors_ccid
        ,ABA.on_account_ccid
        ,ABA.unapplied_ccid
        ,ABA.unidentified_ccid
        ,ABA.remittance_ccid
        ,CJM.trx_code_id
        ,CJM.gl_account_ccid
        ,CJM.reference_txt      
  FROM   ap_bank_accounts       ABA
        ,ce_je_mappings         CJM     
  WHERE ABA.bank_account_id     = p_bank_account_id
  AND   ABA.bank_account_id     = CJM.bank_account_id(+)
  AND   CJM.bank_account_id(+)  = p_bank_account_id
  AND   CJM.trx_code_id(+)      = p_trx_code_id
  AND   NVL(ABA.inactive_date,SYSDATE + 1) > SYSDATE;

  -- -------------------------------------------
  -- Cursor for get the Sum of total amount 
  -- for a lockbox and for date
  -- -------------------------------------------  
  CURSOR lcu_get_sum_lckbx_amt(p_from_date IN DATE
                             , p_to_date   IN DATE)
  IS                              
  SELECT SUM(CSL.amount) tot_lck_amount
        ,CSH.statement_header_id  
        ,SUBSTR(CSL.invoice_text,1,7) invoice_text                
        ,CSH.bank_account_id
        ,CSH.statement_date
  FROM   ce_statement_headers          CSH 
        ,ce_statement_lines            CSL
        ,ap_bank_accounts              ABA
        ,ce_transaction_codes          CTC
  WHERE  CSH.statement_header_id    = CSL.statement_header_id   
  AND    CSH.bank_account_id        = ABA.bank_account_id
  and    csl.trx_code_id            = ctc.transaction_code_id(+)
  AND    CTC.trx_code               = '115'
  AND    CTC.bank_account_id        = ABA.bank_account_id
  AND    (CSL.status IS NULL 
       OR UPPER(CSL.status) = 'UNRECONCILED')
  AND    (CSL.attribute15 IS NULL 
       OR CSL.attribute15 NOT IN('PROCESSED-E1297'))
  AND    CSH.statement_date BETWEEN NVL(p_from_date,CSH.statement_date)  AND NVL(p_to_date,CSH.statement_date)
  AND    ABA.bank_account_type      = 'Corporate - Lockbox'
  AND    NVL(ABA.inactive_date,p_from_date) BETWEEN p_from_date AND p_to_date
  GROUP BY CSH.statement_header_id  
          ,invoice_text 
          ,CSH.bank_account_id
          ,CSH.statement_date          
  ORDER BY CSH.statement_header_id   
          ,invoice_text
          ,CSH.bank_account_id
          ,CSH.statement_date;
          
  -- -------------------------------------------
  -- Get the Chart of Accounts ID
  -- -------------------------------------------
  CURSOR lcu_get_coaid
  IS
  SELECT GSOB.chart_of_accounts_id
  FROM   gl_sets_of_books GSOB
  WHERE  set_of_books_id = gn_set_of_bks_id;  
  /*
  -- -------------------------------------------
  -- Get the Sum of all the receipts Amount 
  -- Lockbox Batch and deposit date
  -- -------------------------------------------
  CURSOR lcu_get_rcpt_amt ( p_bank_account_id  IN ap_bank_accounts_all.bank_account_id%TYPE
                           ,p_deposit_date     IN DATE
                           ,p_batch_name       IN ar_batches_all.name%TYPE)
  IS
  SELECT SUM(CR.AMOUNT)            amount
      ,  CR.deposit_date           deposit_date 
      ,  BAT.lockbox_batch_name    name   
  FROM  ap_bank_branches                         ABB1 
      , ap_bank_accounts                         ABA1 
      , ap_bank_branches                         ABB2 
      , ap_bank_branches                         ABB3 
      , ap_bank_branches                         ABB4 
      , ap_bank_accounts                         ABA2 
      , ar_vat_tax                               VAT
      , hz_cust_accounts                         CUST
      , hz_parties                               PARTY
      , ar_receipt_methods                       REC_METHOD
      , ar_receipt_classes                       RC
      , hz_cust_site_uses                        HCSU 
      , ar_lookups                               ALK1 
      , ar_lookups                               ALK2 
      , ar_lookups                               ALK3 
      , ar_lookups                               ALK4 
      , gl_daily_conversion_types                GL_DCT
      , ar_cash_receipt_history                  CRH_REM
      , ar_batches                               REM_BAT
      , ar_receivables_trx                       REC_TRX
      , ar_distribution_sets                     DIST_SET
      , ar_payment_schedules                     PS
      , ar_cash_receipt_history                  CRH_CURRENT
      , ar_batches                               BAT
      , ar_batches                               BAT_BR
      , ar_cash_receipts                         CR
      , ar_cash_receipt_history                  CRH_FIRST_POSTED 
   WHERE CR.pay_from_customer                             = CUST.cust_account_id ( + ) 
   AND   CUST.party_id                                    = PARTY.party_id ( + ) 
   AND   ALK1.lookup_type( + )                            = 'AR_NOTE_STATUS'
   AND   ALK1.lookup_code( + )                            = CRH_CURRENT.note_status 
   AND   ABB1.bank_branch_id( + )                         = CR.issuer_bank_branch_id 
   AND   ABA1.bank_account_id( + )                        = CR.remittance_bank_account_id 
   AND   ABA1.bank_branch_id                              = ABB2.bank_branch_id ( + ) 
   AND   ABA2.bank_account_id( + )                        = CR.customer_bank_account_id 
   AND   ABA2.bank_branch_id                              = ABB3.bank_branch_id ( + ) 
   AND   CR.customer_bank_branch_id                       = ABB4.bank_branch_id ( + ) 
   AND   VAT.vat_tax_id( + )                              = CR.vat_tax_id 
   AND   CR.receipt_method_id                             = REC_METHOD.receipt_method_id 
   AND   REC_METHOD.receipt_class_id                      = RC.receipt_class_id 
   AND   CR.customer_site_use_id                          = HCSU.site_use_id ( + ) 
   AND   CR.receivables_trx_id                            = REC_TRX.receivables_trx_id ( + ) 
   AND   CR.distribution_set_id                           = DIST_SET.distribution_set_id ( + ) 
   AND   ALK2.lookup_type( + )                            = 'REVERSAL_CATEGORY_TYPE' 
   AND   ALK2.lookup_code( + )                            = CR.reversal_category 
   AND   ALK3.lookup_type( + )                            = 'CKAJST_REASON' 
   AND   ALK3.lookup_code( + )                            = CR.reversal_reason_code 
   AND   ALK4.lookup_code( + )                            = CR.reference_type 
   AND   ALK4.lookup_type( + )                            = 'CB_REFERENCE_TYPE' 
   AND   GL_DCT.conversion_type( + )                      = CR.exchange_rate_type 
   AND   CRH_REM.cash_receipt_id( + )                     = CR.cash_receipt_id 
   AND NOT EXISTS ( SELECT cash_receipt_history_id 
                    FROM   ar_cash_receipt_history CRH3 
                    WHERE  CRH3.status                    = 'REMITTED' 
                    AND    CRH3.cash_receipt_id           = CR.cash_receipt_id 
                    AND    CRH3.cash_receipt_history_id   < CRH_REM.cash_receipt_history_id ) 
   AND CRH_REM.status( + )                                = 'REMITTED' 
   AND CRH_REM.batch_id                                   = REM_BAT.batch_id( + ) 
   AND REM_BAT.type( + )                                  = 'REMITTANCE' 
   AND PS.cash_receipt_id( + )                            = CR.cash_receipt_id 
   AND CRH_CURRENT.cash_receipt_id                        = CR.cash_receipt_id 
   AND CRH_CURRENT.current_record_flag                    = NVL ( 'Y', CR.receipt_number ) 
   AND CRH_FIRST_POSTED.batch_id                          = BAT.batch_id ( + ) 
   AND BAT.TYPE( + )                                      = 'MANUAL' 
   AND CRH_FIRST_POSTED.cash_receipt_id( + )              = CR.cash_receipt_id 
   AND CRH_FIRST_POSTED.first_posted_record_flag( + )     = 'Y' 
   AND CRH_FIRST_POSTED.batch_id                          = BAT_BR.batch_id( + ) 
   AND BAT_BR.type ( + )                                  = 'BR'
   AND ABA1.BANK_ACCOUNT_ID                               = p_bank_account_id
   AND CR.deposit_date                                    = NVL(p_deposit_date,CR.deposit_date)
   AND BAT.lockbox_batch_name                             = NVL(p_batch_name, BAT.lockbox_batch_name )   
   GROUP BY CR.deposit_date 
           ,BAT.lockbox_batch_name;
 */
  -- -------------------------------------------
  -- Get the Trx Type, Trx Code, Trx Description
  -- for Trx Code id and Bank Act Id 
  -- -------------------------------------------    
  CURSOR lcu_get_trx_code (  p_trx_code_id     IN ce_transaction_codes.transaction_code_id%TYPE
                            ,p_bank_account_id IN ap_bank_accounts_all.bank_account_id%TYPE
                            ,p_start_date      IN DATE
                            ,p_end_date        IN DATE)
  IS                            
  SELECT CTC.trx_code
        ,CTC.trx_type
        ,CTC.description
        ,CTC.reconcile_flag
        ,CTC.transaction_code_id
  FROM   CE.ce_transaction_codes    CTC      
  WHERE  CTC.transaction_code_id               =  NVL(p_trx_code_id,CTC.transaction_code_id)
  AND    CTC.bank_account_id                   =  NVL(p_bank_account_id,CTC.bank_account_id)
  AND    CTC.trx_type                          IN('CREDIT','MISC_CREDIT') 
  AND    NVL(CTC.start_date,p_start_date - 1) <=  p_start_date
  AND    NVL(CTC.end_date,p_end_date + 1)     >=  p_end_date ;
 
   -- -------------------------------------------
   -- Get count of the Deposit Currency Code
   -- -------------------------------------------    
   CURSOR lcu_get_cur_code (p_currency_code IN fnd_currencies.currency_code%TYPE)
   IS
   SELECT COUNT(FC.currency_code)
   FROM   fnd_currencies  FC
   WHERE  FC.currency_code = p_currency_code
   AND    FC.enabled_flag  = 'Y'
   AND    FC.currency_flag = 'Y'
   AND    NVL(FC.end_date_active ,SYSDATE +1) > SYSDATE ;
 
  -- -------------------------------------------
  -- Get the Accounting Segments based on the 
  -- CCID from bank Account Setup
  -- -------------------------------------------
  CURSOR lcu_get_aff_segments ( p_code_combination_id  IN gl_code_combinations.code_combination_id%TYPE)
  IS
  SELECT GCC.segment1      company
        ,GCC.segment2      cost_center
        ,GCC.segment3      account 
        ,GCC.segment4      location
        ,GCC.segment5      intercompany
        ,GCC.segment6      channel
        ,GCC.segment7      future
  FROM   gl_code_combinations  GCC 
  WHERE  GCC.code_combination_id = p_code_combination_id
  AND    GCC.enabled_flag        = 'Y';
  
  -- -------------------------------------------
  -- Get the Receipt Method ID
  -- -------------------------------------------  
  CURSOR lcu_get_recpt_method ( p_batch_name    IN ar_batches_all.name%TYPE
                               ,p_deposit_date  IN DATE) 
  IS
  SELECT AB.receipt_method_id
  FROM   ar_batches   AB
  WHERE  AB.lockbox_batch_name  = p_batch_name
  AND    AB.deposit_date        = p_deposit_date;
  
  -- ------------------------------------------------
  -- Get the Transaction Code id
  -- ------------------------------------------------   
  CURSOR lcu_get_001_trx_code (p_bank_account  IN ap_bank_accounts_all.bank_account_id%TYPE)
  IS
  SELECT transaction_code_id  
  FROM   ce_transaction_codes
  WHERE  bank_account_id  = p_bank_account
  AND    trx_code         = '001'
  AND    NVL(end_date, SYSDATE + 1) > SYSDATE;
 
  -- ------------------------------------------------
  -- Cursor to get the Batch Amount for Lockbox
  -- Needs to match with CE Statement tables
  -- ------------------------------------------------
  CURSOR lcu_get_deposit_amt  ( p_lockbox_number   IN  ar_lockboxes_all.lockbox_number%TYPE
                               ,p_bank_account_id  IN  ap_bank_accounts_all.bank_account_id%TYPE
                               ,p_deposit_date     IN  DATE)                               
  IS
  SELECT ABV.lockbox_number
        ,ABV.receipt_method_id
        ,ABV.deposit_date        
        ,SUM(ABV.control_amount) amount 
  FROM   apps.ar_batches_v          ABV
        ,apps.ar_transmissions      ATA
  WHERE  ABV.transmission_id               = ATA.transmission_id
  AND    ATA.status                        = 'CL' 
  AND    ABV.lockbox_number                = SUBSTR(p_lockbox_number,1,7) 
  AND    ABV.remittance_bank_account_id    = p_bank_account_id
  AND    ABV.deposit_date                  = p_deposit_date
  GROUP BY ABV.lockbox_number
          ,ABV.receipt_method_id
          ,ABV.deposit_date
  ORDER BY ABV.deposit_date DESC ;
  
  -- -------------------------------------------
  -- Local Variable Declaration
  -- -------------------------------------------
  bnk_stmt_hdr_line_rec           lcu_bnk_stmt_hdr_line%ROWTYPE;
  get_trx_code_rec                lcu_get_trx_code%ROWTYPE;
  --get_rcpt_amt_rec                lcu_get_rcpt_amt%ROWTYPE;
  get_bank_ccid_rec               lcu_get_bank_ccid%ROWTYPE;
  get_aff_segments_rec            lcu_get_aff_segments%ROWTYPE; 
  get_deposit_amt                 lcu_get_deposit_amt%ROWTYPE;
  get_sum_lckbx_amt               lcu_get_sum_lckbx_amt%ROWTYPE; 
  
  lc_error_details                VARCHAR2(32000);
  lc_error_location               VARCHAR2(32000);
  lc_errmsg                       VARCHAR2(2000);
  lc_output_msg                   VARCHAR2(2000);  
  lc_trx_vald_flag                VARCHAR2(1);  
  lc_source_err_flag              VARCHAR2(1); 
  lc_err_msg                      VARCHAR2(2000); 
  lc_provider_code                VARCHAR2(30); 
  lc_email_addr                   VARCHAR2(60);
  
  lb_amt_match                    BOOLEAN;
   
  ln_success_rec                  NUMBER             := 0;
  ln_total_rec                    NUMBER             := 0;
  ln_error_rec                    NUMBER             := 0;
  ln_currnecy_cnt                 NUMBER             := 0;
  ln_retcode                      NUMBER;
  ln_diff_amount                  NUMBER;
  ln_err_msg_count                NUMBER; 
  ln_group_id                     NUMBER;
  ln_entered_bnk_err_dr_amount    NUMBER;
  ln_entered_bnk_err_cr_amount    NUMBER;
  ln_entered_bnk_csh_dr_amount    NUMBER;
  ln_entered_bnk_csh_cr_amount    NUMBER;  
  ln_receipt_method_id            NUMBER;  
  ln_mail_request_id              NUMBER;
  ln_interface_seq                NUMBER;
  ln_001_trx_code_id              NUMBER ;

  ln_application_id               fnd_application.application_id%TYPE;
  lc_period_name                  gl_period_statuses.period_name%TYPE;
  ln_coa_id                       gl_sets_of_books.chart_of_accounts_id%TYPE; 
  
  EX_MAIN_EXCEPTION               EXCEPTION;

                  
BEGIN  
 
  -- -------------------------------------------
  -- Initializing Local Variables
  -- -------------------------------------------  
  lc_error_location        := 'Initializing Local Variables';
  lc_source_err_flag       := 'N';
  lc_trx_vald_flag         := 'N';
  lc_error_details         := NULL;
  lc_errmsg                := NULL;  
  lc_output_msg            := NULL;
  ln_receipt_method_id     := NULL;
  lc_err_msg               := NULL;
  lc_provider_code         := NULL;
  lb_amt_match             := FALSE;
  ln_retcode               := 0;
  ln_currnecy_cnt          := 0;
  ln_err_msg_count         := 0;
  ln_group_id              := 0;
 
  -- -------------------------------------------
  -- Check the set of Books ID 
  -- -------------------------------------------
  lc_error_location     := 'Mandatory Check Set of Books Id';
  IF gn_set_of_bks_id IS NULL THEN 
    lc_source_err_flag  := 'Y';    
    fnd_message.set_name ('XXFIN','XX_CE_002_SOB_NOT_SETUP'); 
    lc_error_details    := lc_error_details ||fnd_message.get||CHR(10);  
  END IF ;  
  
  -- -------------------------------------------
  -- Get the Chart of Account Id
  -- -------------------------------------------
  IF gn_set_of_bks_id IS NOT NULL THEN       
    OPEN  lcu_get_coaid;
    FETCH lcu_get_coaid INTO ln_coa_id;
    CLOSE lcu_get_coaid;
  
    IF ln_coa_id IS NULL THEN 
      lc_source_err_flag := 'Y';
      fnd_message.set_name ('XXFIN','XX_CE_003_COA_NOT_SETUP'); 
      lc_error_details := lc_error_details ||fnd_message.get||CHR(10);
    END IF ;  
  END IF ;
  
  -- -------------------------------------------
  -- Get one time group id for all the GL 
  -- transaction entry
  -- -------------------------------------------
  SELECT gl_interface_control_s.nextval 
  INTO   ln_group_id
  FROM   DUAL ;
  
  -- -------------------------------------------
  -- Call the Print Message Header
  -- ------------------------------------------- 
  print_message_header 
                   (x_errbuf    =>   lc_errmsg
                   ,x_retcode   =>   ln_retcode
                   ); 
  
  
  -- -------------------------------------------
  -- Total Amount for a Lockbox all the deposit
  --  for a day
  -- -------------------------------------------
  OPEN lcu_get_sum_lckbx_amt ( p_from_date  =>  fnd_conc_date.string_to_date(p_run_from_date)
                              ,p_to_date    =>  fnd_conc_date.string_to_date(p_run_to_date)
                              );
  LOOP  
  FETCH lcu_get_sum_lckbx_amt INTO get_sum_lckbx_amt ;
  EXIT WHEN lcu_get_sum_lckbx_amt%NOTFOUND ;
  
    -- Added on 06-Nov-2007
    -- Amount will be used from batch control amount for lockbox and transmission per day
    lb_amt_match           := FALSE;
    get_deposit_amt.amount := NULL;
    OPEN lcu_get_deposit_amt ( p_lockbox_number    => get_sum_lckbx_amt.invoice_text
                              ,p_bank_account_id   => get_sum_lckbx_amt.bank_account_id
                              ,p_deposit_date      => get_sum_lckbx_amt.statement_date);                                
    FETCH lcu_get_deposit_amt INTO get_deposit_amt;  
    
    -- Assiging the Lb Amount Match if the amount is match then TRUE else FALSE
    IF get_deposit_amt.amount = get_sum_lckbx_amt.tot_lck_amount AND get_deposit_amt.amount IS NOT NULL THEN     
      lb_amt_match := TRUE ; 
    ELSE
      lb_amt_match := FALSE;
    END IF;  
    --End
    -- -------------------------------------------
    -- Loop through all the statement records
    -- for the from and to date range
    -- -------------------------------------------     
    OPEN lcu_bnk_stmt_hdr_line ( p_statement_header_id =>  get_sum_lckbx_amt.statement_header_id
                                ,p_from_date           =>  fnd_conc_date.string_to_date(p_run_from_date)
                                ,p_to_date             =>  fnd_conc_date.string_to_date(p_run_to_date)
                               );
    LOOP
    FETCH lcu_bnk_stmt_hdr_line INTO bnk_stmt_hdr_line_rec ;
    EXIT WHEN lcu_bnk_stmt_hdr_line%NOTFOUND ;
    
      lc_error_details                  := NULL;
      lc_source_err_flag                := 'N'; 
      lc_trx_vald_flag                  := 'N';
      lc_error_location                 := NULL;
      lc_period_name                    := NULL;  
      lc_output_msg                     := NULL;
      ln_currnecy_cnt                   := 0;
      ln_diff_amount                    := 0;
      ln_interface_seq                  := NULL;
      ln_entered_bnk_err_dr_amount      := NULL;
      ln_entered_bnk_err_cr_amount      := NULL;
      ln_entered_bnk_csh_dr_amount      := NULL;
      ln_entered_bnk_csh_cr_amount      := NULL;
      ln_receipt_method_id              := NULL;
      lc_provider_code                  := NULL;
      ln_001_trx_code_id                := NULL;
      
      --
      ln_total_rec:= ln_total_rec + 1;
      --
  
      -- ------------------------------------------------ 
      -- Get the Trx Code Id fo '001'
      -- ------------------------------------------------
      OPEN  lcu_get_001_trx_code ( p_bank_account  => bnk_stmt_hdr_line_rec.bank_account_id);
      FETCH lcu_get_001_trx_code INTO ln_001_trx_code_id;
      CLOSE lcu_get_001_trx_code;    
      -- -------------------------------------------
      -- Check wheather Trx Code '001' is set up or not
      -- -------------------------------------------
      lc_error_location := 'Mandatory Check for Trx Code 001 for each bank account ';
      IF ln_001_trx_code_id IS NULL THEN 
        lc_source_err_flag   := 'Y';   
        lc_error_details     := lc_error_details||'Trx Code is not setup for bank account:'||bnk_stmt_hdr_line_rec.bank_account_num||CHR(10);       
      END IF;     
      -- -------------------------------------------
      -- Validate the Deposit Currency Code
      -- -------------------------------------------
      lc_error_location := 'Mandatory Check for Currency Code';
      IF bnk_stmt_hdr_line_rec.currency_code IS NULL THEN 
        lc_source_err_flag   := 'Y';   
        fnd_message.set_name ('XXFIN','XX_CE_004_NO_CURRENCY_VALUE'); 
        fnd_message.set_token('STATEMENT_NUMBER',bnk_stmt_hdr_line_rec.statement_number);
        fnd_message.set_token('STATEMENT_DATE',bnk_stmt_hdr_line_rec.statement_date);
        fnd_message.set_token('BANK_ACCOUNT',bnk_stmt_hdr_line_rec.bank_account_num);      
        lc_error_details     := lc_error_details||fnd_message.get||CHR(10);    
      ELSE      
        OPEN  lcu_get_cur_code(p_currency_code => bnk_stmt_hdr_line_rec.currency_code);
        FETCH lcu_get_cur_code INTO ln_currnecy_cnt;
        CLOSE lcu_get_cur_code ;
        
        IF ln_currnecy_cnt = 0 THEN
          lc_source_err_flag   := 'Y';   
          fnd_message.set_name ('XXFIN','XX_CE_005_CURRENCY_NOT_SETUP');         
          fnd_message.set_token('CURRENCY_CODE',bnk_stmt_hdr_line_rec.currency_code);        
          fnd_message.set_token('STATEMENT_NUMBER',bnk_stmt_hdr_line_rec.statement_number);
          fnd_message.set_token('STATEMENT_DATE',bnk_stmt_hdr_line_rec.statement_date);
          fnd_message.set_token('BANK_ACCOUNT',bnk_stmt_hdr_line_rec.bank_account_num);        
          lc_error_details     := lc_error_details||fnd_message.get||CHR(10);  
        END IF;
      END IF;    
      -- -------------------------------------------
      -- Validate the transsaction code id
      -- should not be null 
      -- -------------------------------------------     
      lc_error_location := 'Mandatory Check for Transaction Code Id';
      IF bnk_stmt_hdr_line_rec.trx_code_id IS NULL THEN 
        lc_source_err_flag   := 'Y';      
        fnd_message.set_name ('XXFIN','XX_CE_006_NO_TRX_CODE_VALUE'); 
        fnd_message.set_token('STATEMENT_NUMBER',bnk_stmt_hdr_line_rec.statement_number);
        fnd_message.set_token('LINE_NUMBER',bnk_stmt_hdr_line_rec.line_number);
        lc_error_details     := lc_error_details||fnd_message.get||CHR(10);    
      ELSE          
        -- -------------------------------------------
        -- Validate the Transaction Code
        -- -------------------------------------------
        OPEN  lcu_get_trx_code (  p_trx_code_id     => bnk_stmt_hdr_line_rec.trx_code_id
                                 ,p_bank_account_id => bnk_stmt_hdr_line_rec.bank_account_id
                                 ,p_start_date      => fnd_conc_date.string_to_date(p_run_from_date)
                                 ,p_end_date        => fnd_conc_date.string_to_date(p_run_to_date)
                               );
        FETCH lcu_get_trx_code INTO get_trx_code_rec; 
        CLOSE lcu_get_trx_code;
        
        -- -------------------------------------------
        -- Validate / Error for Transaction code
        -- -------------------------------------------
        IF get_trx_code_rec.trx_code IS NULL THEN       
          lc_source_err_flag   := 'Y';   
          lc_trx_vald_flag     := 'Y';
          fnd_message.set_name ('XXFIN','XX_CE_007_TRX_CODE_NOT_SETUP'); 
          fnd_message.set_token('STATEMENT_NUMBER',bnk_stmt_hdr_line_rec.statement_number);
          fnd_message.set_token('LINE_NUMBER',bnk_stmt_hdr_line_rec.line_number);
          fnd_message.set_token('BANK_ACCOUNT',bnk_stmt_hdr_line_rec.bank_account_num);        
          fnd_message.set_token('TRX_ID',bnk_stmt_hdr_line_rec.trx_code_id);
          lc_error_details     := lc_error_details||fnd_message.get||CHR(10);    
        END IF;       
      END IF;
      
      -- -------------------------------------------
      -- Checking the Transaction code 
      -- for Lockbox Deposit
      -- -------------------------------------------
      lc_error_location := 'Check for Transaction code Description for Deposit'; 
      IF lc_trx_vald_flag = 'N' AND lc_source_err_flag = 'N' THEN 
        
        /*Commented on Nov-06-2007*/
        -- Added on 23-oct-2007
        -- Amount will be used from batch control amount for lockbox and transmission per day
        /*
        get_deposit_amt.amount := NULL;
        OPEN lcu_get_deposit_amt ( p_lockbox_number    => bnk_stmt_hdr_line_rec.invoice_text
                                  ,p_bank_account_id   => bnk_stmt_hdr_line_rec.bank_account_id
                                  ,p_deposit_date      => bnk_stmt_hdr_line_rec.statement_date);                                
        FETCH lcu_get_deposit_amt INTO get_deposit_amt;
        CLOSE lcu_get_deposit_amt;
        */
        /* -- Commented on 23-Oct-2007, now Batch control will be used      
        -- -------------------------------------------
        -- Get the Total amount for the same lockbox
        -- and deposit dates OR 
        -- if the batch is there then it will select
        -- btach wise and compare with Net deposit 
        -- in bank for the same lockbox / batch
        -- -------------------------------------------
        OPEN  lcu_get_rcpt_amt ( p_bank_account_id   => bnk_stmt_hdr_line_rec.bank_account_id
                                ,p_deposit_date      => bnk_stmt_hdr_line_rec.statement_date
                                ,p_batch_name        => bnk_stmt_hdr_line_rec.customer_text);
        FETCH lcu_get_rcpt_amt INTO get_rcpt_amt_rec;
        CLOSE lcu_get_rcpt_amt;   
        */ 
        
        /* -- Commented on 23-Oct-2007 for  BOA and 5/3rd Bank are going provide
           -- One deposit per one day per one lockbox
        -- -------------------------------------------
        -- Get the Receipt Method ID 
        -- IF the deposit is Batch level
        -- -------------------------------------------
        IF bnk_stmt_hdr_line_rec.customer_text IS NOT NULL THEN           
          
          -- -------------------------------------------
          -- Get the Receipt Method ID 
          -- By passing receipt date,batch name
          -- -------------------------------------------
          OPEN lcu_get_recpt_method( p_batch_name   =>  bnk_stmt_hdr_line_rec.customer_text
                                    ,p_deposit_date =>  bnk_stmt_hdr_line_rec.trx_date
                                   );
          FETCH lcu_get_recpt_method INTO ln_receipt_method_id ;
          CLOSE lcu_get_recpt_method;           
        END IF;           
        
        -- -------------------------------------------
        -- Provider Code for Open Interface
        -- -------------------------------------------
        IF ln_receipt_method_id IS NOT NULL THEN 
  	  lc_provider_code := 'LOCKBOX_BATCH';
  	ELSE
  	  lc_provider_code := 'LOCKBOX_DAY';
        END IF;  
        */
        -- Added on 23-oct-2007 
        -- All the provider code is LOCKBOX_DAY only for BOA and 5/3rd Bank
        lc_provider_code := 'LOCKBOX_DAY';
        -- End
        /* -- Commented on 23-Oct-2007 
           -- GL Entry not required if amount is not matched for the same lockbox , bank account
           -- and same deposit date
        -- -------------------------------------------
        -- Comparing the Sum of Receipt Amount 
        -- with Net deposit into the Bank
        -- -------------------------------------------
        IF get_rcpt_amt_rec.amount <> bnk_stmt_hdr_line_rec.amount 
          AND get_rcpt_amt_rec.amount IS NOT NULL THEN    
          
          ln_diff_amount := get_rcpt_amt_rec.amount - bnk_stmt_hdr_line_rec.amount ; 
          
          IF ln_diff_amount > 0 THEN 
            -- debit  bank error;
            -- credit cash clearing 
            ln_entered_bnk_err_dr_amount := ln_diff_amount ;
            ln_entered_bnk_err_cr_amount := NULL;               
            ln_entered_bnk_csh_dr_amount := NULL ;
            ln_entered_bnk_csh_cr_amount := ln_diff_amount;               
          ELSE
            -- debit  cash clearing;
            -- credit bank error;
            ln_entered_bnk_err_dr_amount  := NULL;
            ln_entered_bnk_err_cr_amount  := ABS(ln_diff_amount);    
            ln_entered_bnk_csh_dr_amount  := ABS(ln_diff_amount) ;
            ln_entered_bnk_csh_cr_amount  := NULL;
          END IF;  
  
          -- -------------------------------------------
          -- Get the Bank Error CCID from Bank 
          -- Setup Cursor
          -- -------------------------------------------            
          OPEN  lcu_get_bank_ccid ( p_trx_code_id      => bnk_stmt_hdr_line_rec.trx_code_id
                                   ,p_bank_account_id  => bnk_stmt_hdr_line_rec.bank_account_id
                                  );                                     
          FETCH lcu_get_bank_ccid INTO get_bank_ccid_rec;
          CLOSE lcu_get_bank_ccid;                        
          
          -- -------------------------------------------
          -- Get all the accounting segments from 
          -- GL Code Combinations
          -- -------------------------------------------
          IF get_bank_ccid_rec.bank_errors_ccid IS NOT NULL THEN
            OPEN  lcu_get_aff_segments (p_code_combination_id => get_bank_ccid_rec.bank_errors_ccid);
            FETCH lcu_get_aff_segments INTO get_aff_segments_rec;
            CLOSE lcu_get_aff_segments;   
          END IF;  
           
          -- -------------------------------------------
          -- Call the GL Common Package to create 
          -- the difference amt in Bank Error Account
          -- -------------------------------------------                 
          XX_GL_INTERFACE_PKG.create_stg_jrnl_line
                             (  p_status             => 'NEW'
                              , p_date_created       => TRUNC(SYSDATE)
                              , p_created_by         => gn_user_id
                              , p_actual_flag        => 'A'
                              , p_group_id           => ln_group_id                                                                
                              , p_batch_name         => NULL  
                              , p_batch_desc         => NULL 
                              , p_user_source_name   => 'OD CM Lockbox'
                              , p_user_catgory_name  => 'Miscellaneous'
                              , p_set_of_books_id    => gn_set_of_bks_id
                              , p_accounting_date    => TRUNC(SYSDATE)
                              , p_currency_code      => bnk_stmt_hdr_line_rec.currency_code
                              , p_company            => NULL
                              , p_cost_center        => NULL
                              , p_account            => NULL
                              , p_location           => NULL
                              , p_intercompany       => NULL
                              , p_channel            => NULL
                              , p_future             => NULL
                              , p_ccid               => get_bank_ccid_rec.bank_errors_ccid
                              , p_entered_dr         => ln_entered_bnk_err_dr_amount
                              , p_entered_cr         => ln_entered_bnk_err_cr_amount
                              , p_je_line_dsc        => NULL
                              , x_output_msg         => lc_output_msg
                              );
   
          -- -------------------------------------------
          -- Calling the Exception 
          -- If insertion Faild into XX_GL_INTERFACE_NA_STG
          -- ------------------------------------------- 
          lc_error_location := 'Inserting into XX_GL_INTERFACE_NA_STG GL Custom Staging Table';
          IF lc_output_msg IS NOT NULL THEN            
            lc_error_details := lc_error_details ||lc_output_msg||CHR(10) ;
            RAISE EX_MAIN_EXCEPTION;
          END IF;
                   
          -- -------------------------------------------
          -- Call the GL Common Package to create 
          -- the difference amt in Cash Clearing Account 
          -- -------------------------------------------
          XX_GL_INTERFACE_PKG.create_stg_jrnl_line
                             (  p_status             => 'NEW'
                              , p_date_created       => TRUNC(SYSDATE)
                              , p_created_by         => gn_user_id
                              , p_actual_flag        => 'A'
                              , p_group_id           => ln_group_id
                              , p_batch_name         => NULL  
                              , p_batch_desc         => NULL 
                              , p_user_source_name   => 'OD CM Lockbox'
                              , p_user_catgory_name  => 'Miscellaneous'
                              , p_set_of_books_id    => gn_set_of_bks_id
                              , p_accounting_date    => TRUNC(SYSDATE)
                              , p_currency_code      => bnk_stmt_hdr_line_rec.currency_code
                              , p_company            => NULL
                              , p_cost_center        => NULL
                              , p_account            => NULL
                              , p_location           => NULL
                              , p_intercompany       => NULL
                              , p_channel            => NULL
                              , p_future             => NULL
                              , p_ccid               => get_bank_ccid_rec.cash_clearing_ccid
                              , p_entered_dr         => ln_entered_bnk_csh_dr_amount
                              , p_entered_cr         => ln_entered_bnk_csh_cr_amount
                              , p_je_line_dsc        => NULL
                              , x_output_msg         => lc_output_msg
                              );
  
          -- -------------------------------------------
          -- Calling the Exception 
          -- If insertion Faild into XX_GL_INTERFACE_NA_STG
          -- ------------------------------------------- 
          lc_error_location := 'Inserting into XX_GL_INTERFACE_NA_STG GL Custom Staging Table';
          IF lc_output_msg IS NOT NULL THEN            
            lc_error_details := lc_error_details||lc_output_msg||CHR(10) ;
            RAISE EX_MAIN_EXCEPTION;
          END IF;       
          
          -- -------------------------------------------
          -- Calling the Create Open Interface 
          -- Procedure to crerate the record into
          -- XX_CE_999_INTERFACE custom table
          -- for receonciliation
          -- -------------------------------------------
          lc_error_location := 'Inserting into XX_CE_999_INTERFACE table and Updating the CE Statement Header and Lines after processing';
          
          create_open_interface(   p_trx_code_id               =>  bnk_stmt_hdr_line_rec.trx_code_id
                                 , p_bank_account_id           =>  bnk_stmt_hdr_line_rec.bank_account_id
                                 , p_bank_trx_number_org       =>  bnk_stmt_hdr_line_rec.bank_trx_number
                                 , p_trx_date                  =>  bnk_stmt_hdr_line_rec.trx_date
                                 , p_currency_code             =>  bnk_stmt_hdr_line_rec.currency_code  
                                 , p_amount                    =>  bnk_stmt_hdr_line_rec.amount
                                 , p_statement_header_id       =>  bnk_stmt_hdr_line_rec.statement_header_id
                                 , p_statement_line_id         =>  bnk_stmt_hdr_line_rec.statement_line_id
                                 , p_provider_code             =>  lc_provider_code
                                 , p_receipt_method_id         =>  ln_receipt_method_id
                                 , p_lockbox_batch             =>  bnk_stmt_hdr_line_rec.customer_text 
                                 , p_lockbox_deposit_date      =>  get_rcpt_amt_rec.deposit_date
                                 , p_ajb_bank_rec_id           =>  NULL
                                 , x_errbuf                    =>  lc_err_msg
                                 , x_retcode                   =>  ln_retcode  
                                 , x_interface_seq             =>  ln_interface_seq
                                );       
                  
          -- -------------------------------------------
          -- Calling the Update Procedure to Update
          -- the CE_STATEMENT_HEADERS_ALL / 
          -- CE_STATEMENT_LINES after Processing records
          -- -------------------------------------------
          update_stmt_rec( p_bank_stmt_header  => bnk_stmt_hdr_line_rec.statement_header_id 
                          ,p_bank_stmt_line    => bnk_stmt_hdr_line_rec.statement_line_id
                          ,p_bank_account_id   => bnk_stmt_hdr_line_rec.bank_account_id
                          ,p_create_gl         => 'YES'
                          ,p_interface_seq     => ln_interface_seq
                          ,p_001_trx_code      => ln_001_trx_code_id
                          ,x_errbuf            => lc_err_msg
                          ,x_retcode           => ln_retcode           
                          ); 
          
          -- -------------------------------------------
          -- Calling the Exception 
          -- if insertion / updation failed          
          -- -------------------------------------------
          lc_error_location := 'Inserting into XX_CE_999_INTERFACE table and Updating the CE Statement Header and Lines after processing';
          IF ln_retcode = gn_error THEN            
            lc_error_details := lc_err_msg ;
            RAISE EX_MAIN_EXCEPTION;
          END IF;  
            
        ELSIF get_rcpt_amt_rec.amount = bnk_stmt_hdr_line_rec.amount 
            AND get_rcpt_amt_rec.amount IS NOT NULL THEN            
       */ 
       --Commented and added on Nov-06-2007
       --IF get_deposit_amt.amount = bnk_stmt_hdr_line_rec.amount 
       --     AND get_deposit_amt.amount IS NOT NULL THEN   
       IF lb_amt_match = TRUE THEN 
          -- -------------------------------------------
          -- Calling the Create Open Interface 
          -- Procedure to crerate the record into
          -- XX_CE_999_INTERFACE custom table
          -- for receonciliation
          -- -------------------------------------------
          lc_error_location := 'Inserting into XX_CE_999_INTERFACE table and Updating the CE Statement Header and Lines after processing';
          
          create_open_interface(   p_trx_code_id               =>  bnk_stmt_hdr_line_rec.trx_code_id
                                 , p_bank_account_id           =>  bnk_stmt_hdr_line_rec.bank_account_id
                                 , p_bank_trx_number_org       =>  bnk_stmt_hdr_line_rec.bank_trx_number
                                 , p_trx_date                  =>  bnk_stmt_hdr_line_rec.trx_date
                                 , p_currency_code             =>  bnk_stmt_hdr_line_rec.currency_code  
                                 , p_amount                    =>  bnk_stmt_hdr_line_rec.amount
                                 , p_statement_header_id       =>  bnk_stmt_hdr_line_rec.statement_header_id
                                 , p_statement_line_id         =>  bnk_stmt_hdr_line_rec.statement_line_id
                                 , p_provider_code             =>  lc_provider_code
                                 --, p_receipt_method_id         =>  ln_receipt_method_id
                                 , p_receipt_method_id         =>  get_deposit_amt.receipt_method_id
                                 , p_lockbox_batch             =>  bnk_stmt_hdr_line_rec.customer_text 
                                 --, p_lockbox_deposit_date      =>  get_rcpt_amt_rec.deposit_date
                                 , p_lockbox_deposit_date      =>  get_deposit_amt.deposit_date
                                 , p_ajb_bank_rec_id           =>  NULL
                                 , x_errbuf                    =>  lc_err_msg
                                 , x_retcode                   =>  ln_retcode  
                                 , x_interface_seq             =>  ln_interface_seq                               
                               );
                              
          -- -------------------------------------------
          -- Calling the Update Procedure to Update
          -- the CE_STATEMENT_HEADERS_ALL / 
          -- CE_STATEMENT_LINES after Processing records
          -- -------------------------------------------            
          update_stmt_rec( p_bank_stmt_header  => bnk_stmt_hdr_line_rec.statement_header_id 
                          ,p_bank_stmt_line    => bnk_stmt_hdr_line_rec.statement_line_id
                          ,p_bank_account_id   => bnk_stmt_hdr_line_rec.bank_account_id
                          ,p_create_gl         => 'NO'                        
                          ,p_interface_seq     => ln_interface_seq                        
                          ,p_001_trx_code      => ln_001_trx_code_id
                          ,x_errbuf            => lc_err_msg
                          ,x_retcode           => ln_retcode
                         ); 
    
          -- -------------------------------------------
          -- Calling the Exception 
          -- if insertion / updation failed          
          -- -------------------------------------------          
          IF ln_retcode = gn_error THEN            
            lc_error_details := lc_err_msg ;
            RAISE EX_MAIN_EXCEPTION;
          END IF;   
          
        --Commented on Nov-06-2007  
        --ELSIF get_deposit_amt.amount IS NULL 
        --  OR get_deposit_amt.amount <> bnk_stmt_hdr_line_rec.amount THEN           
        ELSE
          -- lb_amt_match = FALSE
        
          fnd_message.set_name ('XXFIN','XX_CE_008_NO_RCPT_AMT'); 
          fnd_message.set_token('STATEMENT_NUMBER',bnk_stmt_hdr_line_rec.statement_number);
          fnd_message.set_token('STATEMENT_DATE',bnk_stmt_hdr_line_rec.statement_date);
          fnd_message.set_token('LINE_NUMBER',bnk_stmt_hdr_line_rec.line_number);
          fnd_message.set_token('LOCKBOX_BATCH',SUBSTR(bnk_stmt_hdr_line_rec.invoice_text,1,7));            
          lc_error_details     := lc_error_details||fnd_message.get||CHR(10);              
          -- -------------------------------------------
          -- Calling the Update Procedure to Update
          -- the CE_STATEMENT_HEADERS_ALL / 
          -- CE_STATEMENT_LINES after Processing records
          -- -------------------------------------------          
          update_stmt_rec( p_bank_stmt_header  => bnk_stmt_hdr_line_rec.statement_header_id 
                          ,p_bank_stmt_line    => bnk_stmt_hdr_line_rec.statement_line_id
                          ,p_bank_account_id   => bnk_stmt_hdr_line_rec.bank_account_id
                          ,p_create_gl         => 'E'
                          ,p_interface_seq     => ln_interface_seq                        
                          ,p_001_trx_code      => NULL
                          ,x_errbuf            => lc_err_msg
                          ,x_retcode           => ln_retcode
                         ); 
          -- -------------------------------------------
          -- Calling the Exception 
          -- if insertion / updation failed          
          -- -------------------------------------------
          lc_error_location := 'Updating the CE Statement Header and Lines after processing';
          IF ln_retcode = gn_error THEN            
            lc_error_details := lc_err_msg ;
            RAISE EX_MAIN_EXCEPTION;
          END IF;                           
                      
        END IF;               
      END IF;  
        -- -------------------------------------------
        -- Call the Print Message Details
        -- ------------------------------------------- 
        print_message_footer 
                          ( x_errbuf              => lc_errmsg
                           ,x_retcode             => ln_retcode
                           ,p_statement_number    => bnk_stmt_hdr_line_rec.statement_number||' / '||bnk_stmt_hdr_line_rec.line_number
                           ,p_lockbox_batch       => SUBSTR(bnk_stmt_hdr_line_rec.invoice_text,1,7)
                           ,p_bank_act_num        => bnk_stmt_hdr_line_rec.bank_account_num
                           ,p_stmt_date           => bnk_stmt_hdr_line_rec.statement_date
                           ,p_message             => NVL(lc_error_details, 'Success') 
                          );
        
        IF lc_error_details IS NULL THEN 
          ln_success_rec := ln_success_rec + 1 ;
        ELSE
          ln_error_rec   := ln_error_rec + 1;
        END IF;
        
    END LOOP;    
    CLOSE lcu_bnk_stmt_hdr_line;
  END LOOP;
  CLOSE lcu_get_sum_lckbx_amt;
  COMMIT;
  
  -- -------------------------------------------
  -- Call the Print Message Record Summary
  -- -------------------------------------------  
  print_message_summary 
                    ( x_errbuf  => lc_errmsg
                     ,x_retcode => ln_retcode
                     ,p_success => ln_success_rec
                     ,p_error   => ln_error_rec
                     ,p_total   => ln_total_rec
                    );     
    
  IF p_email_id IS NOT NULL THEN   
    -- -------------------------------------------
    -- Call the Common Emailer Program
    -- -------------------------------------------    
    ln_mail_request_id := FND_REQUEST.SUBMIT_REQUEST
                                              (application => 'xxfin'
                                              ,program     => 'XXODROEMAILER'
                                              ,description => ''
                                              ,sub_request => FALSE
                                              ,start_time  => TO_CHAR(SYSDATE, 'DD-MON-YY HH:MI:SS')
                                              ,argument1   => '' 
                                              ,argument2   => p_email_id
                                              ,argument3   => 'Lockbox Recon - ' ||TRUNC(SYSDATE)
                                              ,argument4   => ''
                                              ,argument5   => 'Y'
                                              ,argument6   => gn_request_id                                            
                                              );
    COMMIT;
  
  
    IF ln_mail_request_id IS NULL OR ln_mail_request_id = 0 THEN     
      lc_error_location := 'Failed to submit the Standard Common Emailer Program';    
      RAISE EX_MAIN_EXCEPTION;
    END IF;  
  END IF;
  -- -------------------------------------------
  -- Setting the Request Status based one the
  -- Process record count
  -- -------------------------------------------
  IF ln_error_rec > 0 THEN
    x_retcode := gn_warning;
  ELSIF ln_error_rec = 0 THEN
    x_retcode := gn_normal;    
  END IF;                      
  
EXCEPTION  
WHEN EX_MAIN_EXCEPTION THEN     
  x_errbuf := lc_error_location ||'-'||lc_error_details;
  x_retcode:= gn_error;
  -- -------------------------------------------
  -- Call the Custom Common Error Handling 
  -- -------------------------------------------
  XX_COM_ERROR_LOG_PUB.LOG_ERROR 
             (
                p_program_type            => 'CONCURRENT PROGRAM'
               ,p_program_name            => gc_conc_short_name
               ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
               ,p_module_name             => 'CE'
               ,p_error_location          => 'Error at ' || lc_error_location
               ,p_error_message_count     => 1
               ,p_error_message_code      => 'E'
               ,p_error_message           => lc_error_details
               ,p_error_message_severity  => 'Major'
               ,p_notify_flag             => 'N'
               ,p_object_type             => 'LOCKBOX RECONCILIATION'
             );  
  FND_FILE.PUT_LINE(FND_FILE.LOG,'==========================');
  FND_FILE.PUT_LINE(FND_FILE.LOG,x_errbuf); 
WHEN OTHERS THEN
  ROLLBACK;    
  fnd_message.set_name ('XXFIN','XX_CE_001_UNEXPECTED');  
  fnd_message.set_token('PACKAGE','XX_CE_LOCKBOX_RECON_PKG.recon_process');
  fnd_message.set_token('PROGRAM','CE Lockbox Reconciliation');
  fnd_message.set_token('SQLERROR',SQLERRM);
  x_errbuf   := lc_error_location||'-'||lc_error_details||'-'||fnd_message.get;
  x_retcode  := gn_error;
      -- -------------------------------------------
      -- Call the Custom Common Error Handling 
      -- -------------------------------------------
      XX_COM_ERROR_LOG_PUB.LOG_ERROR 
             (
                p_program_type            => 'CONCURRENT PROGRAM'
               ,p_program_name            => gc_conc_short_name
               ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
               ,p_module_name             => 'CE'
               ,p_error_location          => 'Error at ' || lc_error_location
               ,p_error_message_count     => 1
               ,p_error_message_code      => 'E'
               ,p_error_message           => lc_error_details
               ,p_error_message_severity  => 'Major'
               ,p_notify_flag             => 'N'
               ,p_object_type             => 'LOCKBOX RECONCILIATION'
             );        
  FND_FILE.PUT_LINE(FND_FILE.LOG,'==========================');
  FND_FILE.PUT_LINE(FND_FILE.LOG,x_errbuf);  
  --
  
END recon_process;

END XX_CE_LOCKBOX_RECON_PKG;
/
SHOW ERRORS;
EXIT;

-- -------------------------------------------------------------------
-- End of Script                                                   
-- -------------------------------------------------------------------



