CREATE OR REPLACE PACKAGE BODY XX_CE_AJB_CC_RECON_PKG AS 
-- +=================================================================================+
-- |                       Office Depot - Project Simplify                           |
-- |                            Providge Consulting                                  |
-- +=================================================================================+
-- | Name       : XXCEAJBCCRECON.plb                                                 |
-- | Description: Cash Management AJB Creditcard Reconciliation E1310-Extension      |
-- |                                                                                 |
-- |                                                                                 |
-- |                                                                                 |
-- |                                                                                 |
-- |Change Record                                                                    |
-- |==============                                                                   |
-- |Version   Date         Authors            Remarks                                |
-- |========  ===========  ===============    ============================           |
-- |DRAFT 1A  14-AUG-2007  Sunayan Mohanty    Initial draft version                  |
-- +=================================================================================+

  -- -------------------------------------------
  -- Global Variables
  -- -------------------------------------------
  gn_request_id               NUMBER        :=  FND_GLOBAL.CONC_REQUEST_ID;
  gn_user_id                  NUMBER        :=  FND_GLOBAL.USER_ID;
  gn_login_id                 NUMBER        :=  FND_GLOBAL.LOGIN_ID;
  gn_org_id                   NUMBER        :=  FND_PROFILE.VALUE('ORG_ID');
  gn_set_of_bks_id            NUMBER        :=  FND_PROFILE.VALUE('GL_SET_OF_BKS_ID');
  gc_conc_short_name          VARCHAR2(30)  :=  'XXCEAJBRECON';  
  gc_match_conc_short_name    VARCHAR2(30)  :=  'XXCEAJBMATCH';  
  gn_error                    NUMBER        :=  2;
  gn_warning                  NUMBER        :=  1;
  gn_normal                   NUMBER        :=  0;
  gn_coa_id                   NUMBER;
  gn_match_request_id         NUMBER; 
  gc_delimiter                VARCHAR2(30);
  gc_currency_code            VARCHAR2(30); 

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

  FND_FILE.PUT_LINE(FND_FILE.OUTPUT, RPAD('=',50,'=')||'   Cash Management AJB Creditcard Recon    '||RPAD('=',50,'='));
  FND_FILE.NEW_LINE(FND_FILE.OUTPUT,1);      
  
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT, LPAD('AJB Creditcard Reconciliation Extension',76,' '));
  FND_FILE.NEW_LINE(FND_FILE.OUTPUT,1);
  
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'Request ID : '||gn_request_id||RPAD(' ',60,' ')||'Request Date : '||TO_CHAR(SYSDATE,'DD-MON-YYYY HH:MM:SS'));  
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT, RPAD('=',125,'='));   
  
  FND_FILE.NEW_LINE(FND_FILE.OUTPUT,1);  
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT, RPAD('Processor / Store ',23)||RPAD('Process Date',17)||'Description');
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT, RPAD('-',(20-1),'-')||'    '||RPAD('-',(12-1),'-')||'      '||RPAD('-',(25-1),'-')||''||RPAD('-',(120-60),'-'));   

EXCEPTION 
WHEN OTHERS THEN 
  fnd_message.set_name ('XXFIN','XX_CE_001_UNEXPECTED');  
  fnd_message.set_token('PACKAGE','XX_CE_AJB_CC_RECON_PKG.print_message_header');
  fnd_message.set_token('PROGRAM','CE AJB Creditcard Reconciliation Extension');
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
-- | p_processor_id           IN      Message Details                                |
-- | p_store_num                                                                     |
-- | p_process_date                                                                  |
-- | p_message                                                                       |
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
                         ,p_processor_id         IN         VARCHAR2
                         ,p_store_num            IN         NUMBER
                         ,p_process_date         IN         DATE
                         ,p_message              IN         VARCHAR2
                         )
IS

BEGIN
  
  IF p_message IS NULL THEN     
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,LPAD(NVL(p_processor_id,'')||'/'|| p_store_num,25) ||'       '||LPAD(NVL(p_process_date,''),10)||'                 '||REPLACE(p_message,CHR(10),CHR(10)||LPAD(' ',(40),' ')));
  ELSE    
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,LPAD(NVL(p_processor_id,'')||'/'|| p_store_num,25) ||'       '||LPAD(NVL(p_process_date,''),10)||'       '||REPLACE(p_message,CHR(10),CHR(10)||LPAD(' ',(40),' ')));
  END IF;
  
EXCEPTION 
WHEN OTHERS THEN 
  fnd_message.set_name ('XXFIN','XX_CE_001_UNEXPECTED');  
  fnd_message.set_token('PACKAGE','XX_CE_AJB_CC_RECON_PKG.print_message_footer');
  fnd_message.set_token('PROGRAM','CE AJB Creditcard Reconciliation Extension');
  fnd_message.set_token('SQLERROR',SQLERRM);
  x_errbuf   := fnd_message.get;  
  x_retcode  := gn_error;
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
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'CE AJB Creditcard Reconciliation Extension : '||'E1310');
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'===============================================================');
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Total Records Found               : '||NVL(p_total,0));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Error Records                     : '||NVL(p_error,0));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Success Records                   : '||NVL(p_success,0));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'===============================================================');  
  ELSE  
    -------------------------------------------------------------------------------------------------------------
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, RPAD('-',50,'-')||'  No Record Found for Processing   '||RPAD('-',45,'-'));
    -------------------------------------------------------------------------------------------------------------
  END IF;
    
EXCEPTION 
WHEN OTHERS THEN 
  fnd_message.set_name ('XXFIN','XX_CE_001_UNEXPECTED');  
  fnd_message.set_token('PACKAGE','XX_CE_AJB_CC_RECON_PKG.print_message_summary');
  fnd_message.set_token('PROGRAM','CE AJB Creditcard Reconciliation');
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
-- |p_trx_date               IN      Trnsaction Code ID                              |
-- |p_currency_code          IN      Currency Code                                   |
-- |p_country_code           IN      Country Code                                    | 
-- |p_amount                 IN      Amount                                          |
-- |p_provider_code          IN      Provider Name                                   |   
-- |p_vset_file              IN      Vset File                                       |
-- |                                                                                 |
-- |PREREQUISITES                                                                    |
-- |  None.                                                                          |
-- |                                                                                 |
-- |CALLED BY                                                                        |
-- |  Accrual_Process                                                                |
-- +=================================================================================+ 
PROCEDURE create_open_interface
                          ( x_errbuf                    OUT   NOCOPY  VARCHAR2
                          , x_retcode                   OUT   NOCOPY  NUMBER
                          , p_trx_date                  IN            DATE        DEFAULT NULL
                          , p_currency_code             IN            VARCHAR2    DEFAULT NULL   
                          , p_country_code              IN            VARCHAR2    DEFAULT NULL
                          , p_amount                    IN            NUMBER      DEFAULT NULL
                          , p_provider_code             IN            VARCHAR2    DEFAULT NULL  
                          , p_vset_file                 IN            VARCHAR2    DEFAULT NULL  
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
  INSERT INTO xx_ce_999_interface (  trx_number
                                   , trx_id              
                                   , record_type
                                   , trx_type
                                   , status
                                   , amount
                                   , trx_date     
                                  --, country_code
                                   , ajb_file_number
                                   , creation_date           
                                   , created_by              
                                   , last_update_date        
                                   , last_updated_by
                                  ) 
                        VALUES    (  ln_ce_interface_seq
                                   , ln_ce_interface_seq
                                   , p_provider_code
                                   , 'CASH'
                                   , 'FLOAT'
                                   , p_amount
                                   , p_trx_date
                                  -- , p_country_code
                                   , p_vset_file
                                   , SYSDATE
                                   , gn_user_id
                                   , SYSDATE
                                   , gn_user_id 
                                   );
                                   
EXCEPTION 
WHEN OTHERS THEN 
  fnd_message.set_name ('XXFIN','XX_CE_001_UNEXPECTED');  
  fnd_message.set_token('PACKAGE','XX_CE_AJB_CC_RECON_PKG.create_open_interface');
  fnd_message.set_token('PROGRAM','CE AJB Creditcard Reconciliation');
  fnd_message.set_token('SQLERROR',SQLERRM);
  x_errbuf   := fnd_message.get;  
  x_retcode  := gn_error;
  FND_FILE.PUT_LINE(FND_FILE.LOG,'==========================');
  FND_FILE.PUT_LINE(FND_FILE.LOG,x_errbuf);   
END create_open_interface; 

-- +=================================================================================+
-- |                                                                                 |
-- |PROCEDURE                                                                        |
-- |  reverse_daily_accrual                                                          |
-- |                                                                                 |
-- |DESCRIPTION                                                                      |
-- | This procedure will be used to create                                           |
-- | Accrual GL Accounting entries                                                   |
-- |                                                                                 |
-- |PARAMETERS                                                                       |
-- |==========                                                                       |
-- |NAME                    TYPE    DESCRIPTION                                      |
-- |----------------------- ------- ----------------------------------------         |
-- |x_errmsg                 OUT     Error message.                                  |
-- |x_retstatus              OUT     Error code.                                     |
-- |                                                                                 |
-- |PREREQUISITES                                                                    |
-- |  None.                                                                          |
-- |                                                                                 |
-- |CALLED BY                                                                        |
-- |  accrual_process                                                                |
-- +=================================================================================+ 
PROCEDURE reverse_daily_accrual
                          ( x_errmsg                    OUT   NOCOPY  VARCHAR2
                          , x_retstatus                 OUT   NOCOPY  NUMBER
                          --, p_processor_code            IN            VARCHAR2
                          --, p_process_date              IN            DATE
                          , p_veset_file                IN            VARCHAR2
                          )
IS

  -- ------------------------------------------------
  -- Get all the AJB accrual records for 
  -- each processor code to create accrual entries
  -- ------------------------------------------------
  -- Check the trnasaction is daily accrual or not
  -- 
  CURSOR lcu_get_rev_journal ( p_vset_num IN VARCHAR2
                             )
  IS  
  SELECT DECODE(GJL.entered_dr,NULL,GJL.entered_cr)rev_entered_dr
        ,DECODE(GJL.entered_cr,NULL,GJL.entered_dr)rev_entered_cr
        ,GJL.code_combination_id  rev_ccid 
        ,GJH.currency_code        func_currency_code
  FROM   gl_je_headers   GJH
        ,gl_je_lines     GJL
  WHERE  GJH.je_header_id      =  GJL.je_header_id
  AND    GJL.set_of_books_id   =  gn_set_of_bks_id
  AND    GJL.attribute15       =  p_vset_num;

  -- -------------------------------------------
  -- Local Variable Declaration
  -- -------------------------------------------
  get_rev_journal_rec        lcu_get_rev_journal%ROWTYPE;
    
  ln_group_id                NUMBER;  
  lc_output_msg              VARCHAR2(2000);
  lc_error_location          VARCHAR2(2000);  
  
  EX_REV_ACCRUAL             EXCEPTION;
    
BEGIN
  -- -------------------------------------------
  -- Get one time group id for all the GL 
  -- Accrual entry for the same set of book
  -- -------------------------------------------
  SELECT gl_interface_control_s.nextval 
  INTO   ln_group_id
  FROM   DUAL ;  
  -- ------------------------------------------------
  -- Loop through all the R type record for 
  -- Daily Reversal
  -- ------------------------------------------------
  OPEN  lcu_get_rev_journal( p_vset_num  => p_veset_file
                           );
  LOOP
  FETCH lcu_get_rev_journal INTO  get_rev_journal_rec;
  EXIT WHEN lcu_get_rev_journal%NOTFOUND;
    -- -------------------------------------------
    -- Call the GL Common Package to create 
    -- Reversal of Previous Month Accrual Entry
    -- -------------------------------------------
    lc_error_location := 'Reversal Accrual Entries for a Daily Record';
    XX_GL_INTERFACE_PKG.create_stg_jrnl_line
                             (  p_status             => 'NEW'
                              , p_date_created       => TRUNC(SYSDATE)
                              , p_created_by         => gn_user_id
                              , p_actual_flag        => 'A'
                              , p_group_id           => ln_group_id
                              , p_batch_name         => NULL  
                              , p_batch_desc         => NULL 
                              , p_user_source_name   => 'OD CM Credit Settlement System'
                              , p_user_catgory_name  => 'Miscellaneous'
                              , p_set_of_books_id    => gn_set_of_bks_id
                              , p_accounting_date    => TRUNC(SYSDATE)
                              , p_currency_code      => get_rev_journal_rec.func_currency_code
                              , p_company            => NULL
                              , p_cost_center        => NULL
                              , p_account            => NULL
                              , p_location           => NULL
                              , p_intercompany       => NULL
                              , p_channel            => NULL
                              , p_future             => NULL
                              , p_ccid               => get_rev_journal_rec.rev_ccid
                              , p_entered_dr         => get_rev_journal_rec.rev_entered_dr
                              , p_entered_cr         => get_rev_journal_rec.rev_entered_cr
                              , p_je_line_dsc        => NULL
                              , x_output_msg         => lc_output_msg
                              );     
    -- -------------------------------------------
    -- Calling the Exception 
    -- If insertion Faild into XX_GL_INTERFACE_NA_STG
    -- -------------------------------------------         
    IF lc_output_msg IS NOT NULL THEN            
      x_errmsg := lc_output_msg ;
      RAISE EX_REV_ACCRUAL;
    END IF;            
    
  END LOOP;  
  COMMIT;
  CLOSE lcu_get_rev_journal;
    
EXCEPTION 
WHEN EX_REV_ACCRUAL THEN     
  x_errmsg   := lc_error_location ||'-'||lc_output_msg;
  x_retstatus:= gn_error;
  FND_FILE.PUT_LINE(FND_FILE.LOG,'==========================');
  FND_FILE.PUT_LINE(FND_FILE.LOG,x_errmsg); 
WHEN OTHERS THEN   
  fnd_message.set_name ('XXFIN','XX_CE_001_UNEXPECTED');  
  fnd_message.set_token('PACKAGE','XX_CE_AJB_CC_RECON_PKG.reverse_daily_accrual');
  fnd_message.set_token('PROGRAM','CE AJB Creditcard Reconciliation');
  fnd_message.set_token('SQLERROR',SQLERRM);
  x_errmsg     := fnd_message.get;  
  x_retstatus  := gn_error;
  FND_FILE.PUT_LINE(FND_FILE.LOG,'==========================');
  FND_FILE.PUT_LINE(FND_FILE.LOG,x_errmsg);   
END reverse_daily_accrual;  

-- +=================================================================================+
-- |                                                                                 |
-- |PROCEDURE                                                                        |
-- |  accrual_process                                                                |
-- |                                                                                 |
-- |DESCRIPTION                                                                      |
-- | This procedure will be used to create                                           |
-- | Accrual GL Accounting entries                                                   |
-- |                                                                                 |
-- |PARAMETERS                                                                       |
-- |==========                                                                       |
-- |NAME                    TYPE    DESCRIPTION                                      |
-- |----------------------- ------- ----------------------------------------         |
-- |x_errmsg                 OUT     Error message.                                  |
-- |x_retstatus              OUT     Error code.                                     |
-- |                                                                                 |
-- |PREREQUISITES                                                                    |
-- |  None.                                                                          |
-- |                                                                                 |
-- |CALLED BY                                                                        |
-- |  recon_process                                                                  |
-- +=================================================================================+ 
PROCEDURE accrual_process
                          ( x_errmsg                      OUT   NOCOPY  VARCHAR2
                          , x_retstatus                   OUT   NOCOPY  NUMBER
                          )
IS

  -- ------------------------------------------------
  -- Get all the accrual account details from 
  -- custom accrual setup tables
  -- ------------------------------------------------
  CURSOR lcu_get_accrual_accounts  ( p_processor       IN VARCHAR2
                                    ,p_process_date    IN DATE)
  IS 
  SELECT  XCGH.provider_type
         ,XCGH.provider_code
         ,XCAD.charge_code
         ,XCAD.charge_description
         ,XCAD.charge_percentage
         ,XCAD.costcenter
         ,XCAD.charge_debit_act
         ,XCAD.charge_credit_act
         ,XCAD.location_from
         ,XCAD.effective_from_date
         ,XCAD.effective_to_date
         ,XCAD.accrual_frequency
         ,XCGH.accrual_liability_costcenter
         ,XCGH.accrual_liability_account
         ,XCGH.accrual_liability_location
  FROM    xx_ce_accrual_glact_dtl   XCAD
         ,xx_ce_recon_glact_hdr     XCGH
  WHERE   XCGH.header_id            = XCAD.header_id
  AND     XCGH.provider_code        = p_processor
  AND     XCGH.set_of_books_id      = gn_set_of_bks_id
  AND     p_process_date BETWEEN XCAD.effective_from_date 
  AND     NVL(XCAD.effective_to_date, p_process_date + 1);

  -- ------------------------------------------------
  -- Get all the AJB accrual records for 
  -- each processor code to create accrual entries
  -- for record type 'S'
  -- ------------------------------------------------
  CURSOR lcu_get_accrual_record 
  IS
  SELECT  XC9A.record_type
         ,XC9A.provider_name
         ,XC9A.file_creation_date
         ,XC9A.file_creation_time
         ,XC9A.file_seq_num
         ,XC9A.file_gross_amt
         ,XC9A.file_net_amt
         ,XC9A.batch_num
         ,XC9A.vset_file
         ,XC9A.payment_date
         ,XC9A.rowid
  FROM    xx_ce_ajb999a        XC9A
  WHERE   XC9A.record_type       = 'S'
--  AND     XC9A.provider_name     = p_processor_name
--  AND     XC9A.vset_file         = p_vset_num
  AND    (XC9A.status_1310 IS NULL 
       OR XC9A.status_1310 NOT IN ('PROCESSED')) ;  

  -- ------------------------------------------------
  -- Get all the AJB reversal  accrual records for 
  -- each processor code to create accrual entries
  -- for record type 'R'
  -- ------------------------------------------------
  CURSOR lcu_get_rev_accrual_record 
  IS
  SELECT  XC9A.record_type
         ,XC9A.provider_name
         ,XC9A.file_creation_date
         ,XC9A.file_creation_time
         ,XC9A.file_seq_num
         ,XC9A.file_gross_amt
         ,XC9A.file_net_amt
         ,XC9A.batch_num
         ,XC9A.vset_file
         ,XC9A.payment_date
         --,XC9A.currency_code
         --,XC9A.country_code
         ,XC9A.rowid
  FROM    xx_ce_ajb999a        XC9A
  WHERE   XC9A.record_type       = 'R'
--  AND     XC9A.provider_name     = p_processor_name
--  AND     XC9A.vset_file         = p_vset_num
  AND    (XC9A.status_1310 IS NULL 
       OR XC9A.status_1310 NOT IN ('PROCESSED')) ;
  
  -- ------------------------------------------------
  -- Get the Application ID
  -- ------------------------------------------------
  CURSOR lcu_get_application
  IS
  SELECT FAP.application_id  
  FROM   fnd_application FAP
  WHERE  FAP.application_short_name = 'SQLGL';  
  
  -- ------------------------------------------------
  -- Cursor to get the Future Period Name and 
  -- Validate the Accounting Date
  -- ------------------------------------------------
  CURSOR lcu_get_gl_future_periods( p_application_id  NUMBER)
  IS
  SELECT GPS1.start_date
        ,GPS1.end_date
        ,GPS1.period_name
  FROM   gl_period_statuses GPS1
  WHERE  GPS1.application_id               = p_application_id
  AND    GPS1.set_of_books_id              = gn_set_of_bks_id
  AND    GPS1.closing_status               IN ('O','F')
  AND    GPS1.start_date                   = (SELECT GPS.end_date + 1
                                              FROM   gl_period_statuses GPS        
                                              WHERE  GPS.set_of_books_id    = gn_set_of_bks_id
                                              AND    GPS.closing_status     IN ('O','F')
                                              AND    TO_DATE(TRUNC(SYSDATE),'DD-MON-RRRR') BETWEEN GPS.start_date 
                                                                                         AND GPS.end_date 
                                              AND    GPS.application_id      = p_application_id);
  
  -- -------------------------------------------
  -- Local Variable Declaration
  -- -------------------------------------------
  get_accrual_record              lcu_get_accrual_record%ROWTYPE;   
  get_accrual_accounts_rec        lcu_get_accrual_accounts%ROWTYPE;
  get_gl_future_periods_rec       lcu_get_gl_future_periods%ROWTYPE;
  get_rev_accrual_record          lcu_get_rev_accrual_record%ROWTYPE;
  
  lc_company                      VARCHAR2(30);
  lc_account                      VARCHAR2(30);
  lc_lob                          VARCHAR2(30);
  lc_intercompany                 VARCHAR2(30)     := '0000';
  lc_future                       VARCHAR2(30)     := '000000';
  lc_accrual_error                VARCHAR2(4000);
  lc_error                        VARCHAR2(2000);
  lc_error_flag                   VARCHAR2(1)      := 'N';
  lc_output_msg                   VARCHAR2(1000);
  lc_error_location               VARCHAR2(2000);
  lc_accr_liab_cost               VARCHAR2(150);
  lc_accr_liab_acct		  VARCHAR2(150);
  lc_accr_liab_loc 		  VARCHAR2(150);
  lc_accr_liab_company            VARCHAR2(150);
  lc_accr_liab_lob                VARCHAR2(150);
  
  ln_per_amt                      NUMBER;
  ln_entered_dr_amount            NUMBER;
  ln_entered_cr_amount            NUMBER;
  ln_group_id                     NUMBER;
  ln_application_id               NUMBER;
  ln_ccid                         NUMBER;
  ln_total_cr_amount              NUMBER;
  ln_accr_liab_ccid               NUMBER;
  ln_rev_ccid                     NUMBER;
  ln_retcode                      NUMBER;
  
  EX_ACCRUAL                      EXCEPTION;
  
BEGIN 

  -- ------------------------------------------------
  -- Get the Application ID
  -- ------------------------------------------------
  OPEN  lcu_get_application;
  FETCH lcu_get_application INTO ln_application_id;
  CLOSE lcu_get_application;
  
  -- -------------------------------------------
  -- Get one time group id for all the GL 
  -- Accrual entry for the same set of book
  -- -------------------------------------------
  SELECT gl_interface_control_s.nextval 
  INTO   ln_group_id
  FROM   DUAL ; 
   
  -- ------------------------------------------------
  -- Loop through all the processor records in 
  -- AJB accrual records
  -- ------------------------------------------------
  OPEN lcu_get_accrual_record ;
  LOOP
  FETCH lcu_get_accrual_record INTO get_accrual_record;
  EXIT WHEN lcu_get_accrual_record%NOTFOUND;
  
    ln_total_cr_amount    := NULL;
    lc_accr_liab_company  := NULL;
    lc_accr_liab_cost     := NULL;
    lc_accr_liab_acct     := NULL;
    lc_accr_liab_loc      := NULL;
    lc_accr_liab_lob      := NULL;
    ln_accr_liab_ccid     := NULL;
    -- ------------------------------------------------
    -- Get the Percentage and Accounting segments  
    -- for create GL accrual entries
    -- ------------------------------------------------
    lc_error_location := 'Loop through all the accrual accounts';
    OPEN lcu_get_accrual_accounts ( p_processor    => get_accrual_record.provider_name
                                   ,p_process_date => TRUNC(SYSDATE)
                                   );
    LOOP                                    
    FETCH lcu_get_accrual_accounts INTO get_accrual_accounts_rec;
    EXIT WHEN lcu_get_accrual_accounts%NOTFOUND;
      
      lc_accrual_error       := NULL;
      lc_account             := NULL;
      lc_lob                 := NULL;
      lc_error_flag          := 'N';
      ln_per_amt             := 0;
      ln_entered_dr_amount   := NULL;
      lc_output_msg          := NULL;
      lc_accr_liab_cost      := get_accrual_accounts_rec.accrual_liability_costcenter;
      lc_accr_liab_acct      := get_accrual_accounts_rec.accrual_liability_account;
      lc_accr_liab_loc       := get_accrual_accounts_rec.accrual_liability_location;
      
      -- ------------------------------------------------
      -- Get the Accounting segments for Corporate Acts
      -- ------------------------------------------------
      -- Get the Company based on the location
      -- ------------------------------------------------       
      IF lc_accr_liab_company IS NULL THEN 
        lc_error_location := 'Derive the Liability Company from location ';            
        lc_accr_liab_company := XX_GL_TRANSLATE_UTL_PKG.DERIVE_COMPANY_FROM_LOCATION (p_location  => lc_accr_liab_loc); 
      END IF;
      
      lc_error_location := 'Derive the Company from location ';      
      lc_company := XX_GL_TRANSLATE_UTL_PKG.DERIVE_COMPANY_FROM_LOCATION (p_location  => get_accrual_accounts_rec.location_from); 
      
      IF (lc_company IS NULL OR lc_accr_liab_company IS NULL) THEN         
        fnd_message.set_name ('XXFIN','XX_CE_020_COMPANY_NOT_SETUP'); 
        lc_accrual_error     := lc_accrual_error||fnd_message.get||CHR(10);            
      END IF;
      -- ------------------------------------------------
      -- Get the LOB Based on Costcenter and Location
      -- ------------------------------------------------   
      IF lc_accr_liab_lob IS NULL THEN 
        lc_error_location := 'Derive the Liability Lob from location and costcenter ';      
        XX_GL_TRANSLATE_UTL_PKG.derive_lob_from_costctr_loc 
                                 ( p_location       => lc_accr_liab_loc
                                  ,p_cost_center    => lc_accr_liab_cost
                                  ,x_lob            => lc_accr_liab_lob
                                  ,x_error_message  => lc_error
                                  );
      END IF;
      
      lc_error_location := 'Derive the Lob from location and costcenter ';
      XX_GL_TRANSLATE_UTL_PKG.derive_lob_from_costctr_loc 
                               ( p_location       => get_accrual_accounts_rec.location_from
                                ,p_cost_center    => get_accrual_accounts_rec.costcenter
                                ,x_lob            => lc_lob
                                ,x_error_message  => lc_error
                                );
                                
                              
      IF (lc_lob IS NULL OR lc_accr_liab_lob IS NULL) THEN         
        fnd_message.set_name ('XXFIN','XX_CE_021_LOB_NOT_SETUP'); 
        lc_accrual_error    := lc_accrual_error||fnd_message.get||CHR(10);        
      END IF;  

      -- ------------------------------------------------
      -- Get Account Code Combination Id
      -- ------------------------------------------------  
      lc_error_location := 'Get the CCID based from statndard api fnd_flex_ext.get_ccid ';
      IF lc_error_flag = 'N' THEN
      
        -- ------------------------------------------------
        -- Get CCID of Liability Accrual Liability
        -- ------------------------------------------------
        IF (ln_accr_liab_ccid IS NULL OR ln_accr_liab_ccid = 0 )THEN 
        
          ln_accr_liab_ccid := fnd_flex_ext.get_ccid
                                         ( application_short_name      => 'SQLGL'
                                          ,key_flex_code               => 'GL#'
                                          ,structure_number            => gn_coa_id
                                          ,validation_date             => SYSDATE
                                          ,concatenated_segments       => lc_company   
                                                                        ||gc_delimiter 
                                                                        ||lc_accr_liab_cost
                                                                        ||gc_delimiter
                                                                        ||get_accrual_accounts_rec.accrual_liability_account 
                                                                        ||gc_delimiter
                                                                        ||lc_accr_liab_loc
                                                                        ||gc_delimiter
                                                                        ||lc_intercompany
                                                                        ||gc_delimiter
                                                                        ||lc_accr_liab_lob
                                                                        ||gc_delimiter
                                                                        ||lc_future
                                           );   
      
       
          IF ln_accr_liab_ccid = 0 THEN        
            lc_error   := fnd_flex_ext.get_message;                                           
            FND_FILE.PUT_LINE(FND_FILE.LOG,'GET_CCID: '||SUBSTR(lc_error,1,200));
            fnd_message.set_name ('XXFIN','XX_CE_023_CCID_NOT_SETUP'); 
            lc_accrual_error    := lc_accrual_error||lc_error||fnd_message.get||CHR(10);  
            lc_error_flag       := 'Y';      
            RAISE EX_ACCRUAL ;
          END IF;
        END IF;

        -- ------------------------------------------------
        -- Get the CCID  
        -- ------------------------------------------------
        ln_ccid := fnd_flex_ext.get_ccid
                             (  application_short_name      => 'SQLGL'
                               ,key_flex_code               => 'GL#'
                               ,structure_number            => gn_coa_id
                               ,validation_date             => SYSDATE
                               ,concatenated_segments       => lc_company   
                                                             ||gc_delimiter 
                                                             ||get_accrual_accounts_rec.costcenter
                                                             ||gc_delimiter
                                                             ||get_accrual_accounts_rec.charge_debit_act 
                                                             ||gc_delimiter
                                                             ||get_accrual_accounts_rec.location_from
                                                             ||gc_delimiter
                                                             ||lc_intercompany
                                                             ||gc_delimiter
                                                             ||lc_lob
                                                             ||gc_delimiter
                                                             ||lc_future
                             );   
      
       
        IF ln_ccid = 0 THEN        
          lc_error   := fnd_flex_ext.get_message;                                           
          FND_FILE.PUT_LINE(FND_FILE.LOG,'GET_CCID: '||SUBSTR(lc_error,1,200));
          fnd_message.set_name ('XXFIN','XX_CE_023_CCID_NOT_SETUP'); 
          lc_accrual_error    := lc_accrual_error||lc_error||fnd_message.get||CHR(10);  
          lc_error_flag       := 'Y';      
          RAISE EX_ACCRUAL ;
        END IF;          
        
      END IF;        
      -- ------------------------------------------------
      -- Create Accounting Entries 
      -- By calling common custom GL package
      -- ------------------------------------------------
      IF lc_error_flag = 'N' THEN
      
        ln_per_amt := (get_accrual_record.file_gross_amt / 100) * get_accrual_accounts_rec.charge_percentage;                
        ln_entered_dr_amount := ln_per_amt;          
        ln_total_cr_amount   := ln_total_cr_amount + ln_entered_dr_amount ;
        -- -------------------------------------------
        -- Call the GL Common Package to create 
        -- GL Accrual Entry
        -- Check if possible populate the Accrual Frequency (Daily / Monthly)
        -- -------------------------------------------
        lc_error_location := 'Create Accrual Journal Entries for each record';
        XX_GL_INTERFACE_PKG.create_stg_jrnl_line
                           (  p_status             => 'NEW'
                            , p_date_created       => TRUNC(SYSDATE)
                            , p_created_by         => gn_user_id
                            , p_actual_flag        => 'A'
                            , p_group_id           => ln_group_id
                            , p_batch_name         => NULL
                            , p_batch_desc         => NULL
                            , p_user_source_name   => 'OD CM Credit Settlement System'
                            , p_user_catgory_name  => 'Miscellaneous'
                            , p_set_of_books_id    => gn_set_of_bks_id
                            , p_accounting_date    => TRUNC(SYSDATE)
                            , p_currency_code      => gc_currency_code
                            , p_company            => NULL
                            , p_cost_center        => NULL
                            , p_account            => NULL
                            , p_location           => NULL
                            , p_intercompany       => NULL
                            , p_channel            => NULL
                            , p_future             => NULL
                            , p_ccid               => ln_ccid
                            , p_entered_dr         => ln_entered_dr_amount
                            , p_entered_cr         => NULL
                            , p_je_line_dsc        => NULL
                            , x_output_msg         => lc_output_msg
                            );
                                   
        -- -------------------------------------------
        -- Calling the Exception 
        -- If insertion Faild into XX_GL_INTERFACE_NA_STG
        -- -------------------------------------------         
        IF lc_output_msg IS NOT NULL THEN            
          lc_accrual_error := lc_accrual_error||lc_output_msg ;
          RAISE EX_ACCRUAL;
        END IF;                           
        -- -------------------------------------------
        -- Check the accrual Frequency 
        -- If it is Monthly then enter the reversal
        -- accrual entry for start date of next 
        -- GL open period
        -- -------------------------------------------
        IF get_accrual_accounts_rec.accrual_frequency = 'MONTHLY' 
          AND get_accrual_accounts_rec.location_from = '010000' THEN
         
          OPEN  lcu_get_gl_future_periods( p_application_id    => ln_application_id
                                         );
          FETCH lcu_get_gl_future_periods INTO get_gl_future_periods_rec;
          CLOSE lcu_get_gl_future_periods;          
          
          
          IF get_gl_future_periods_rec.period_name IS NULL THEN
            fnd_message.set_name ('XXFIN','XX_CE_024_GL_PERIOD_NOT_SETUP'); 
            lc_accrual_error    := lc_accrual_error||fnd_message.get||CHR(10);                                
            lc_error_flag := 'Y' ;                              
          END IF ;          
          
          IF lc_error_flag = 'N' THEN           
            -- -------------------------------------------
            -- Call the GL Common Package to create 
            -- Reversal of Previous Month Accrual Entry
            -- -------------------------------------------
            FOR i IN 1..2 LOOP
              
              IF i = 1 THEN  
                ln_entered_cr_amount := ln_per_amt; 
                ln_entered_dr_amount := NULL;
                ln_rev_ccid          := ln_ccid;              
              ELSIF i = 2 THEN                     
                ln_entered_dr_amount := ln_per_amt; 
                ln_entered_cr_amount := NULL;
                ln_rev_ccid          := ln_accr_liab_ccid;              
              ELSE
                FND_FILE.PUT_LINE(FND_FILE.LOG,'Monthly Reversal Accrual Entry For Storre Num 010000');
              END IF;   
              
              lc_error_location := 'Create Reversal Accrual Journal Entries for Monthly record';
              XX_GL_INTERFACE_PKG.create_stg_jrnl_line
                               (  p_status             => 'NEW'
                                , p_date_created       => TRUNC(SYSDATE)
                                , p_created_by         => gn_user_id
                                , p_actual_flag        => 'A'
                                , p_group_id           => ln_group_id
                                , p_batch_name         => NULL  
                                , p_batch_desc         => NULL 
                                , p_user_source_name   => 'OD CM Credit Settlement System'
                                , p_user_catgory_name  => 'Miscellaneous'
                                , p_set_of_books_id    => gn_set_of_bks_id
                                , p_accounting_date    => get_gl_future_periods_rec.start_date
                                , p_currency_code      => gc_currency_code
                                , p_company            => NULL
                                , p_cost_center        => NULL
                                , p_account            => NULL
                                , p_location           => NULL
                                , p_intercompany       => NULL
                                , p_channel            => NULL
                                , p_future             => NULL
                                , p_ccid               => ln_rev_ccid
                                , p_entered_dr         => ln_entered_dr_amount
                                , p_entered_cr         => ln_entered_cr_amount
                                , p_je_line_dsc        => NULL
                                , x_output_msg         => lc_output_msg
                                ); 
              -- -------------------------------------------
              -- Calling the Exception 
              -- If insertion Faild into XX_GL_INTERFACE_NA_STG
              -- -------------------------------------------         
              IF lc_output_msg IS NOT NULL THEN            
                lc_accrual_error := lc_accrual_error||lc_output_msg ;
                RAISE EX_ACCRUAL;
              END IF;    
            END LOOP; -- For Loop ....
          END IF;          
        END IF;         
      END IF;        
    END LOOP;
    CLOSE lcu_get_accrual_accounts;    
    -- -------------------------------------------
    -- 
    -- -------------------------------------------
    IF ln_total_cr_amount IS NOT NULL THEN     
      -- -------------------------------------------
      -- Call the GL Common Package to create 
      -- GL Accrual Entry
      -- Check if possible populate the Accrual Frequency (Daily / Monthly)
      -- ------------------------------------------- 
      lc_error_location := 'Create Accrual Journal Entries for each record';
      XX_GL_INTERFACE_PKG.create_stg_jrnl_line
                           (  p_status             => 'NEW'
                            , p_date_created       => TRUNC(SYSDATE)
                            , p_created_by         => gn_user_id
                            , p_actual_flag        => 'A'
                            , p_group_id           => ln_group_id
                            , p_batch_name         => NULL
                            , p_batch_desc         => NULL
                            , p_user_source_name   => 'OD CM Credit Settlement System'
                            , p_user_catgory_name  => 'Miscellaneous'
                            , p_set_of_books_id    => gn_set_of_bks_id
                            , p_accounting_date    => TRUNC(SYSDATE)
                            , p_currency_code      => gc_currency_code
                            , p_company            => NULL
                            , p_cost_center        => NULL
                            , p_account            => NULL
                            , p_location           => NULL
                            , p_intercompany       => NULL
                            , p_channel            => NULL
                            , p_future             => NULL
                            , p_ccid               => ln_accr_liab_ccid
                            , p_entered_dr         => NULL
                            , p_entered_cr         => ln_total_cr_amount
                            , p_je_line_dsc        => NULL
                            , x_output_msg         => lc_output_msg
                            );
                                   
      -- -------------------------------------------
      -- Calling the Exception 
      -- If insertion Faild into XX_GL_INTERFACE_NA_STG
      -- -------------------------------------------         
      IF lc_output_msg IS NOT NULL THEN            
        lc_accrual_error := lc_accrual_error||lc_output_msg ;
        RAISE EX_ACCRUAL;
      END IF;       
    END IF;
    -- -------------------------------------------
    -- Update the Status of Record Type 'S'
    -- -------------------------------------------
    UPDATE xx_ce_ajb999a  XC9A
    SET    XC9A.status_1310     = 'PROCESSED'
    WHERE  XC9A.rowid           = get_accrual_record.rowid
    AND    XC9A.record_type     = 'S'
    AND    XC9A.provider_name   = get_accrual_record.provider_name;
    
  END LOOP;
  CLOSE lcu_get_accrual_record; 
  -- -------------------------------------------
  -- Loop through all the 'R' record type 
  -- for call the reversal accrual entries
  -- after getting the reconcile record
  -- -------------------------------------------
  OPEN lcu_get_rev_accrual_record ;
  LOOP 
  FETCH lcu_get_rev_accrual_record INTO get_rev_accrual_record;
  EXIT WHEN lcu_get_rev_accrual_record%NOTFOUND;   
    
    -- -------------------------------------------
    -- Call the insert procedure to create all 
    -- the un-processed record type'R' into the 
    -- custom interface table XX_CE_999_INTERFACE 
    -- for E-1295 Reconciliation Process
    -- -------------------------------------------
    lc_error_location := 'Inserting into XX_CE_999_INTERFACE table without matching with bank statement lines';
        
    create_open_interface(   p_trx_date                  =>  get_rev_accrual_record.payment_date
                           , p_currency_code             =>  NULL
                           , p_country_code              =>  NULL
                           , p_amount                    =>  get_rev_accrual_record.file_net_amt
                           , p_provider_code             =>  get_rev_accrual_record.provider_name
                           , p_vset_file                 =>  get_rev_accrual_record.vset_file
                           , x_errbuf                    =>  lc_error
                           , x_retcode                   =>  ln_retcode          
                         ); 

    -- -------------------------------------------
    -- Calling the reversal entry procedure
    -- -------------------------------------------
    lc_error_location := 'Calling Reversal Accrual Entry';
    reverse_daily_accrual( x_errmsg            =>  lc_error
                          ,x_retstatus         =>  ln_retcode
                          --,p_processor_code    =>  get_rev_accrual_record.provider_name
                          --,p_process_date      =>  TRUNC(SYSDATE)
                          ,p_veset_file        =>  get_rev_accrual_record.vset_file
                          ); 
    

    IF ln_retcode = gn_error  THEN
      lc_accrual_error := lc_accrual_error||lc_error ;
      RAISE EX_ACCRUAL;
    END IF;  
    -- -------------------------------------------
    -- Update the Status of Record Type 'R'
    -- -------------------------------------------    
    UPDATE xx_ce_ajb999a  XC9A
    SET    XC9A.status_1310    = DECODE(ln_retcode,gn_normal,'PROCESSED',gn_error,'ERRORED',gn_warning,'WARNING')
    WHERE  XC9A.rowid          = get_rev_accrual_record.rowid
    AND    XC9A.record_type    = 'R'
    AND    XC9A.provider_name  = get_rev_accrual_record.provider_name;
    
  END LOOP;
  CLOSE lcu_get_rev_accrual_record;
  
  --COMMIT;
EXCEPTION  
WHEN EX_ACCRUAL THEN     
  x_errmsg   := lc_error_location ||'-'||lc_accrual_error;
  x_retstatus:= gn_error;
  FND_FILE.PUT_LINE(FND_FILE.LOG,'==========================');
  FND_FILE.PUT_LINE(FND_FILE.LOG,x_errmsg);                                   
WHEN OTHERS THEN   
  fnd_message.set_name ('XXFIN','XX_CE_001_UNEXPECTED');  
  fnd_message.set_token('PACKAGE','XX_CE_AJB_CC_RECON_PKG.accrual_process');
  fnd_message.set_token('PROGRAM','CE AJB Creditcard Reconciliation');
  fnd_message.set_token('SQLERROR',SQLERRM);
  x_errmsg     := fnd_message.get;  
  x_retstatus  := gn_error;
  FND_FILE.PUT_LINE(FND_FILE.LOG,'==========================');
  FND_FILE.PUT_LINE(FND_FILE.LOG,x_errmsg);   
END accrual_process;  

-- +=================================================================================+
-- |                                                                                 |
-- |PROCEDURE                                                                        |
-- |  recon_process                                                                  |
-- |                                                                                 |
-- |DESCRIPTION                                                                      |
-- | Procedure to process the 999 Store Records and call the reversal process        |
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
-- |  recon_process                                                                  |
-- |                                                                                 |
-- |                                                                                 |
-- |                                                                                 |
-- +=================================================================================+ 
PROCEDURE  recon_process
                        (x_errbuf               OUT   NOCOPY   VARCHAR2
                        ,x_retcode              OUT   NOCOPY   NUMBER
                        ,p_email_id             IN             VARCHAR2    DEFAULT NULL                      
                        ,p_match_process        IN             VARCHAR2    DEFAULT NULL                      
                        --,p_run_from_date        IN             VARCHAR2
                        --,p_run_to_date          IN             VARCHAR2
                        )
IS

  -- -------------------------------------------
  -- Get the Sum of all the receipts Amount 
  -- Lockbox Batch and deposit date
  -- -------------------------------------------
  CURSOR lcu_get_recon_dtl ( p_processor      IN VARCHAR2
                            ,p_process_date   IN DATE
                            ,p_store_num      IN NUMBER
                           )
  IS
  SELECT XCGH.header_id
        ,XCGH.provider_type
        ,XCGH.provider_code   
        ,XCGH.set_of_books_id
        ,XCGH.clearing_costcenter
        ,XCGH.clearing_account      
        ,XCRD.details_id
        ,XCRD.charge_code
        ,XCRD.charge_description
        ,XCRD.costcenter
        ,XCRD.charge_debit_act
        ,XCRD.charge_credit_act
        ,XCRD.location_from
        ,XCRD.location_to
        ,XCRD.effective_from_date
        ,XCRD.effective_to_date
  FROM   xx_ce_recon_glact_hdr    XCGH
        ,xx_ce_recon_glact_dtl    XCRD
  WHERE  XCGH.provider_code    = p_processor
  AND    XCGH.set_of_books_id  = gn_set_of_bks_id
  AND    XCGH.header_id        = XCRD.header_id
  AND    p_store_num  BETWEEN XCRD.location_from AND XCRD.location_to
  AND    p_process_date BETWEEN XCRD.effective_from_date
  AND    NVL(XCRD.effective_to_date, p_process_date + 1);

  -- -------------------------------------------
  -- Get all the un-processed store number 
  -- and procesor id 
  -- -------------------------------------------
  CURSOR lcu_get_store_processor
  IS
  SELECT  XCA9.store_num
         ,XCA9.provider_type
         ,XCA9.submission_date
         ,XCA9.processor_id
         ,XCA9.rowid
  FROM    xx_ce_ajb999  XCA9
  WHERE  (XCA9.status_1310 IS NULL 
       OR XCA9.status_1310 NOT IN ('PROCESSED'));  
 
  -- -------------------------------------------
  -- Get sum of all the fees for store,processor
  -- and submission date
  -- -------------------------------------------
  CURSOR lcu_get_fees_store_processor ( p_store_num       IN NUMBER
                                       ,p_processor_id    IN VARCHAR2
                                       ,p_submission_date IN DATE)                                       
  IS
  SELECT  SUM(XCA9.discount_amt)           discount_amt
         ,SUM(XCA9.monthly_discount_amt)   monthly_discount_amt
         ,SUM(XCA9.monthly_assessment_fee) monthly_assessment_fee
         ,SUM(XCA9.service_fee)            service_fee
         ,SUM(XCA9.adj_fee)                adj_fee
         ,SUM(XCA9.cost_funds_amt)         cost_funds_amt
         ,SUM(XCA9.reserved_amt)           reserved_amt 
  FROM    xx_ce_ajb999  XCA9
  WHERE  (XCA9.status_1310 IS NULL 
       OR XCA9.status_1310 NOT IN ('PROCESSED'))
  AND     XCA9.store_num          =   p_store_num
  AND     XCA9.processor_id       =   p_processor_id
  AND     XCA9.submission_date    =   p_submission_date   
  GROUP BY XCA9.processor_id
          ,XCA9.submission_date
          ,XCA9.store_num;  

  -- -------------------------------------------
  -- Get the Chart of Accounts ID
  -- -------------------------------------------
  CURSOR lcu_get_coaid
  IS
  SELECT GSOB.chart_of_accounts_id
        ,GSOB.currency_code 
  FROM   gl_sets_of_books GSOB
  WHERE  set_of_books_id = gn_set_of_bks_id;  
  
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
  -- Local Variable Declaration
  -- -------------------------------------------
  get_store_processor             lcu_get_store_processor%ROWTYPE;   
  get_aff_segments_rec            lcu_get_aff_segments%ROWTYPE; 
  get_fees_store_processor        lcu_get_fees_store_processor%ROWTYPE;
  get_recon_dtl                   lcu_get_recon_dtl%ROWTYPE;  
  
  lc_error_details                VARCHAR2(32000);
  lc_error_location               VARCHAR2(32000);
  lc_errmsg                       VARCHAR2(2000);
  lc_output_msg                   VARCHAR2(2000);  
  lc_trx_vald_flag                VARCHAR2(1);  
  lc_source_err_flag              VARCHAR2(1); 
  lc_err_msg                      VARCHAR2(2000); 
  lc_provider_code                VARCHAR2(30); 
  lc_email_addr                   VARCHAR2(60); 
  lc_sql                          VARCHAR2(4000);
  lc_recon_company                VARCHAR2(150);
  lc_intercompany                 VARCHAR2(30)     := '0000';
  lc_future                       VARCHAR2(30)     := '000000';  
  lc_recon_lob                    VARCHAR2(150);  
  lc_recon_clearing_lob		  VARCHAR2(150);
  lc_error_flag                   VARCHAR2(1)      :='N';
  
  ln_success_rec                  NUMBER           := 0;
  ln_total_rec                    NUMBER           := 0;
  ln_error_rec                    NUMBER           := 0;
  ln_currnecy_cnt                 NUMBER           := 0;
  ln_retcode                      NUMBER;
  ln_diff_amount                  NUMBER;
  ln_err_msg_count                NUMBER; 
  ln_group_id                     NUMBER;
  ln_charge_amt                   NUMBER;
  ln_recon_clr_ccid               NUMBER;
  ln_entered_dr_amount            NUMBER;
  ln_entered_cr_amount            NUMBER;
  ln_recon_ccid                   NUMBER;
  ln_ccid                         NUMBER;
  ln_mail_request_id              NUMBER;

  ln_application_id               fnd_application.application_id%TYPE;
  lc_period_name                  gl_period_statuses.period_name%TYPE;
  
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
  lc_err_msg               := NULL;
  lc_provider_code         := NULL;
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
    FETCH lcu_get_coaid INTO gn_coa_id, gc_currency_code;
    CLOSE lcu_get_coaid;
  
    IF gn_coa_id IS NULL THEN 
      lc_source_err_flag := 'Y';
      fnd_message.set_name ('XXFIN','XX_CE_003_COA_NOT_SETUP'); 
      lc_error_details := lc_error_details ||fnd_message.get||CHR(10);
    END IF ;  
  END IF ;

  -- -------------------------------------------
  -- Get the Delimiter
  -- -------------------------------------------  
  gc_delimiter := fnd_flex_ext.get_delimiter
                             ( application_short_name  => 'SQLGL'
                              ,key_flex_code           => 'GL#'
                              ,structure_number        => gn_coa_id);   

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
  -- Call the Accrual Procedure for Record type'S'
  -- -------------------------------------------  
  accrual_process( x_errmsg           =>  lc_errmsg
                  ,x_retstatus        =>  ln_retcode 
                 ); 
  
  IF ln_retcode = gn_error THEN   
    lc_error_location := 'Error when calling the acrual procedure-' ; 
    lc_error_details  := lc_error_details|| lc_errmsg ;
    RAISE EX_MAIN_EXCEPTION ;
  END IF;  
  
  -- -------------------------------------------
  -- Loop through all the statement records
  -- for the from and to date range
  -- -------------------------------------------     
  lc_error_location := 'Loop Through all the store 999 un-processed records';
  OPEN lcu_get_store_processor;
  LOOP
  FETCH lcu_get_store_processor INTO get_store_processor ;
  EXIT WHEN lcu_get_store_processor%NOTFOUND ;
  
    lc_error_details                  := NULL;
    lc_source_err_flag                := 'N'; 
    lc_trx_vald_flag                  := 'N';
    lc_period_name                    := NULL;  
    lc_output_msg                     := NULL;
    ln_currnecy_cnt                   := 0;
    ln_diff_amount                    := 0;   
    lc_provider_code                  := NULL;
    lc_sql                            := NULL;
    lc_recon_company                  := NULL;
    ln_recon_clr_ccid                 := NULL;
    lc_recon_clearing_lob             := NULL;
    ln_entered_dr_amount              := NULL;
    ln_entered_cr_amount              := NULL;
    lc_recon_lob                      := NULL;
    ln_ccid                           := NULL;
    
    --
    ln_total_rec:= ln_total_rec + 1;
    --
    
    -- -------------------------------------------
    --
    -- -------------------------------------------   
    lc_error_location := 'Derive the Company from location ';      
    lc_recon_company  := XX_GL_TRANSLATE_UTL_PKG.DERIVE_COMPANY_FROM_LOCATION (p_location  => get_store_processor.store_num); 
    
    IF lc_recon_company IS NULL THEN         
      fnd_message.set_name ('XXFIN','XX_CE_020_COMPANY_NOT_SETUP'); 
      lc_error_details     := lc_error_location||fnd_message.get||CHR(10);            
    END IF;    
    -- -------------------------------------------
    --
    -- -------------------------------------------
    OPEN lcu_get_recon_dtl (  p_processor         =>  get_store_processor.processor_id
    			     ,p_process_date	  =>  TRUNC(SYSDATE)
    			     ,p_store_num   	  =>  get_store_processor.store_num
    			   );
    LOOP
    FETCH lcu_get_recon_dtl INTO get_recon_dtl;
    EXIT WHEN lcu_get_recon_dtl%NOTFOUND;
      ln_charge_amt            := NULL;
      ln_recon_clr_ccid        := NULL;
      ln_recon_ccid            := NULL;
      ln_entered_dr_amount     := NULL;
      ln_entered_cr_amount     := NULL;
      lc_recon_lob             := NULL;
      lc_recon_clearing_lob    := NULL;
      -- -------------------------------------------
      -- Dynamic Sql to get the 999 store column value
      -- -------------------------------------------
      lc_sql := 'SELECT :charge_code
                 FROM  xx_ce_ajb999 
                 WHERE store_num        = :store_num
                 AND   processor_id     = :processor_id
                 AND   submission_date  = :submission_date
                 AND  (status_1310 IS NULL 
                    OR status_1310 NOT IN (''PROCESSED''))';
                
      EXECUTE IMMEDIATE  lc_sql USING get_recon_dtl.charge_code ,get_store_processor.store_num ,get_store_processor.processor_id ,get_store_processor.submission_date RETURNING INTO ln_charge_amt;
      
      IF ln_charge_amt IS NOT NULL THEN 
        -- -------------------------------------------
        --
        -- -------------------------------------------
        lc_error_location := 'Derive the Clearing Lob from location and costcenter ';
        XX_GL_TRANSLATE_UTL_PKG.derive_lob_from_costctr_loc 
                                 ( p_location       => get_store_processor.store_num
                                  ,p_cost_center    => get_recon_dtl.clearing_costcenter
                                  ,x_lob            => lc_recon_clearing_lob
                                  ,x_error_message  => lc_errmsg
                                  );                                
                              
        IF lc_recon_clearing_lob IS NULL THEN         
          fnd_message.set_name ('XXFIN','XX_CE_021_LOB_NOT_SETUP'); 
          lc_error_details    := lc_error_details||lc_errmsg||fnd_message.get||CHR(10);        
        END IF;          
        -- -------------------------------------------
        -- 
        -- -------------------------------------------
        lc_error_location := 'Derive the Lob from location and costcenter ';
        XX_GL_TRANSLATE_UTL_PKG.derive_lob_from_costctr_loc 
                                 ( p_location       => get_store_processor.store_num
                                  ,p_cost_center    => get_recon_dtl.costcenter
                                  ,x_lob            => lc_recon_lob
                                  ,x_error_message  => lc_errmsg
                                  );
                              
        IF lc_recon_lob IS NULL THEN         
          fnd_message.set_name ('XXFIN','XX_CE_021_LOB_NOT_SETUP'); 
          lc_error_details    := lc_error_details||lc_errmsg||fnd_message.get||CHR(10);
        END IF;     
        -- ------------------------------------------------
        -- Get CCID From Recon Clearing Accounting Segments
        -- ------------------------------------------------
        ln_recon_clr_ccid := fnd_flex_ext.get_ccid
                                  ( application_short_name      => 'SQLGL'
                                   ,key_flex_code               => 'GL#'
                                   ,structure_number            => gn_coa_id
                                   ,validation_date             => SYSDATE
                                   ,concatenated_segments       => lc_recon_company   
                                                                 ||gc_delimiter 
                                                                 ||get_recon_dtl.clearing_costcenter
                                                                 ||gc_delimiter
                                                                 ||get_recon_dtl.clearing_account 
                                                                 ||gc_delimiter
                                                                 ||get_store_processor.store_num
                                                                 ||gc_delimiter
                                                                 ||lc_intercompany
                                                                 ||gc_delimiter
                                                                 ||lc_recon_clearing_lob
                                                                 ||gc_delimiter
                                                                 ||lc_future
                                    );   
      
        IF ln_recon_clr_ccid = 0 THEN                    
          fnd_message.set_name ('XXFIN','XX_CE_023_CCID_NOT_SETUP'); 
          lc_error_details    := lc_error_details||fnd_message.get||CHR(10);  
          lc_error_flag       := 'Y';      
          --RAISE EX_MAIN_EXCEPTION ;
        END IF;
        -- ------------------------------------------------
        -- Get CCID From Recon Clearing Accounting Segments
        -- ------------------------------------------------
        ln_recon_ccid := fnd_flex_ext.get_ccid
                                  ( application_short_name      => 'SQLGL'
                                   ,key_flex_code               => 'GL#'
                                   ,structure_number            => gn_coa_id
                                   ,validation_date             => SYSDATE
                                   ,concatenated_segments       => lc_recon_company   
                                                                 ||gc_delimiter 
                                                                 ||get_recon_dtl.costcenter
                                                                 ||gc_delimiter
                                                                 ||get_recon_dtl.charge_credit_act 
                                                                 ||gc_delimiter
                                                                 ||get_store_processor.store_num
                                                                 ||gc_delimiter
                                                                 ||lc_intercompany
                                                                 ||gc_delimiter
                                                                 ||lc_recon_lob
                                                                 ||gc_delimiter
                                                                 ||lc_future
                                    );   
      
       
        IF ln_recon_ccid = 0 THEN                    
          fnd_message.set_name ('XXFIN','XX_CE_023_CCID_NOT_SETUP'); 
          lc_error_details    := lc_error_details||fnd_message.get||CHR(10);  
          lc_error_flag       := 'Y';      
          --RAISE EX_MAIN_EXCEPTION ;
        END IF;
        
        FOR i IN 1..2 LOOP
          
          IF i = 1 THEN           
            ln_entered_dr_amount := ln_charge_amt ;
            ln_entered_cr_amount := NULL;
            ln_ccid              := ln_recon_ccid;          
          ELSIF i = 2 THEN             
            ln_entered_dr_amount := NULL ;
            ln_entered_cr_amount := ln_charge_amt;
            ln_ccid              := ln_recon_clr_ccid;            
          END IF;          
          -- -------------------------------------------
          -- Create Journal Entries for Reconciliation
          -- -------------------------------------------
          lc_error_location := 'Create Reconciliation Journal Entries for each provider and store';
          XX_GL_INTERFACE_PKG.create_stg_jrnl_line
                               (  p_status             => 'NEW'
                                , p_date_created       => TRUNC(SYSDATE)
                                , p_created_by         => gn_user_id
                                , p_actual_flag        => 'A'
                                , p_group_id           => ln_group_id
                                , p_batch_name         => NULL  
                                , p_batch_desc         => NULL 
                                , p_user_source_name   => 'OD CM Credit Settlement System'
                                , p_user_catgory_name  => 'Miscellaneous'
                                , p_set_of_books_id    => gn_set_of_bks_id
                                , p_accounting_date    => TRUNC(SYSDATE)
                                , p_currency_code      => gc_currency_code
                                , p_company            => NULL
                                , p_cost_center        => NULL
                                , p_account            => NULL
                                , p_location           => NULL
                                , p_intercompany       => NULL
                                , p_channel            => NULL
                                , p_future             => NULL
                                , p_ccid               => ln_ccid
                                , p_entered_dr         => ln_entered_dr_amount
                                , p_entered_cr         => ln_entered_cr_amount
                                , p_je_line_dsc        => NULL
                                , x_output_msg         => lc_output_msg
                                ); 
            -- -------------------------------------------
            -- Calling the Exception 
            -- If insertion Faild into XX_GL_INTERFACE_NA_STG
            -- -------------------------------------------         
            IF lc_output_msg IS NOT NULL THEN            
              lc_error_details    := lc_error_details||lc_output_msg ;
              lc_error_flag       := 'Y';
            END IF;          
          
        END LOOP;
      END IF;      
    END LOOP;
    CLOSE lcu_get_recon_dtl;     
    -- -------------------------------------------
    -- Update after the Process the records
    -- -------------------------------------------    
    UPDATE xx_ce_ajb999  XCA9
    SET    XCA9.status_1310    = DECODE(lc_error_flag,'Y','ERRORED','N','PROCESSED',XCA9.status_1310)
    WHERE  XCA9.rowid          = get_store_processor.rowid
    AND    XCA9.store_num      = get_store_processor.store_num
    AND    XCA9.processor_id   = get_store_processor.processor_id; 
    
    -- -------------------------------------------
    -- Call the Print Message Details
    -- ------------------------------------------- 
    print_message_footer 
                        ( x_errbuf              => lc_errmsg
                         ,x_retcode             => ln_retcode
                         ,p_processor_id        => get_store_processor.processor_id
                         ,p_store_num           => get_store_processor.store_num
                         ,p_process_date        => TRUNC(SYSDATE)
                         ,p_message             => NVL(lc_error_details, 'Success') 
                        );
      
    IF lc_error_details IS NULL THEN 
      ln_success_rec := ln_success_rec + 1 ;
    ELSE
      ln_error_rec   := ln_error_rec + 1;
    END IF;
      
  END LOOP;
  CLOSE lcu_get_store_processor;
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
                                            ,argument3   => 'AJB Recon Process - ' ||TRUNC(SYSDATE)
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
  
  IF p_match_process ='Y' THEN   
    -- -------------------------------------------
    -- Call the Bank Statement Match Process
    -- -------------------------------------------    
    gn_match_request_id := FND_REQUEST.SUBMIT_REQUEST
                                            (application => 'xxfin'
                                            ,program     => gc_match_conc_short_name
                                            ,description => ''
                                            ,sub_request => FALSE
                                            ,start_time  => TO_CHAR(SYSDATE, 'DD-MON-YY HH:MI:SS')
                                            ,argument1   => p_email_id
                                            );
    COMMIT;
    
    IF gn_match_request_id IS NULL OR gn_match_request_id = 0 THEN     
      lc_error_location := 'Failed to submit the AJB Statement Match Program';    
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
END recon_process;

-- +=================================================================================+
-- |                                                                                 |
-- |PROCEDURE                                                                        |
-- |  print_match_summary                                                            |
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
-- |                                                                                 |
-- |PREREQUISITES                                                                    |
-- |  None.                                                                          |
-- |                                                                                 |
-- |CALLED BY                                                                        |
-- |  recon_process                                                                  |
-- +=================================================================================+ 
PROCEDURE print_match_summary
                           (x_errbuf                 OUT   NOCOPY VARCHAR2
                           ,x_retcode                OUT   NOCOPY NUMBER
                           ,p_total                  IN           NUMBER    DEFAULT NULL
                           ,p_toal_match             IN           NUMBER    DEFAULT NULL
                           ,p_match_request_id       IN           NUMBER    DEFAULT NULL
                           ,p_processor_id           IN           VARCHAR2  DEFAULT NULL
                           ,p_statement_number       IN           VARCHAR2  DEFAULT NULL
                           ,p_statement_line_number  IN           NUMBER    DEFAULT NULL
                           ,p_message                IN           VARCHAR2  DEFAULT NULL
                           ,p_print_option           IN           VARCHAR2  
                           )
IS

lc_status   VARCHAR2 (30);

BEGIN

  
  IF p_print_option = 'DETAIL' THEN 
    
    IF p_message  = 'Y' THEN 
      lc_status  := 'Matched' ;
    ELSE
      lc_status  := 'Not Matched' ;
    END IF;  
    -- ------------------------------------------------
    -- Set the Concurrent program Output header display
    -- ------------------------------------------------
    FND_FILE.NEW_LINE(FND_FILE.OUTPUT,1);
    FND_FILE.NEW_LINE(FND_FILE.OUTPUT,1);
   
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, RPAD('=',50,'=')||'   Cash Management AJB Statement Matching    '||RPAD('=',50,'='));
    FND_FILE.NEW_LINE(FND_FILE.OUTPUT,1);      
    
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, LPAD('AJB Creditcard Reconciliation Extension',76,' '));
    FND_FILE.NEW_LINE(FND_FILE.OUTPUT,1);
    
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'Request ID : '||p_match_request_id||RPAD(' ',60,' ')||'Request Date : '||TO_CHAR(SYSDATE,'DD-MON-YYYY HH:MM:SS'));  
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, RPAD('=',125,'='));   
    
    FND_FILE.NEW_LINE(FND_FILE.OUTPUT,1);  
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, RPAD('Processor ',23)||RPAD('Statement Hdr/Line #',17)||'Description');
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, RPAD('-',(20-1),'-')||'    '||RPAD('-',(12-1),'-')||'      '||RPAD('-',(25-1),'-')||''||RPAD('-',(120-60),'-'));   
    
    IF p_message IS NULL THEN     
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,LPAD(NVL(p_processor_id,''),25)||'    '|| LPAD(NVL(p_statement_number,''),25)||'/'||LPAD(NVL(p_statement_number,''),25)||'        '||REPLACE(lc_status,CHR(10),CHR(10)||LPAD(' ',(40),' ')));
    ELSE    
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,LPAD(NVL(p_processor_id,''),25)||'    '|| LPAD(NVL(p_statement_number,''),25)||'/'||LPAD(NVL(p_statement_number,''),25)||'       '||REPLACE(lc_status,CHR(10),CHR(10)||LPAD(' ',(40),' ')));
    END IF;
  
  ELSIF p_print_option = 'SUMMARY' THEN 
  
    IF p_total > 0 THEN
      
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'===============================================================');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'CE AJB Creditcard Reconciliation Extension : '||'E1310');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'===============================================================');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Total Records Found               : '||NVL(p_total,0));
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Total Match                       : '||NVL(p_toal_match,0));
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Not Match                         : '||TO_CHAR(NVL(p_total,0) - NVL(p_toal_match,0)));
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'===============================================================');  
      -------------------------------------------------------------------------------------------------
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, RPAD('=',50,'=')||'   End Process Details    '||RPAD('=',45,'='));
      -------------------------------------------------------------------------------------------------
    ELSE  
      -------------------------------------------------------------------------------------------------------------
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, RPAD('-',50,'-')||'  No Record Found for Processing   '||RPAD('-',45,'-'));
      -------------------------------------------------------------------------------------------------------------
    END IF;
  END IF;  
EXCEPTION 
WHEN OTHERS THEN 
  fnd_message.set_name ('XXFIN','XX_CE_001_UNEXPECTED');  
  fnd_message.set_token('PACKAGE','XX_CE_AJB_CC_RECON_PKG.print_match_summary');
  fnd_message.set_token('PROGRAM','CE AJB Creditcard Reconciliation');
  fnd_message.set_token('SQLERROR',SQLERRM);
  x_errbuf   := fnd_message.get;  
  x_retcode  := gn_error;
  FND_FILE.PUT_LINE(FND_FILE.LOG,'==========================');
  FND_FILE.PUT_LINE(FND_FILE.LOG,x_errbuf);   
END print_match_summary;

-- +=================================================================================+
-- | Name        : GET_PROVIDER_CODE                                                 |
-- | Description : This function will be used to get the valid                       |
-- |               Provider Code from Bank Deposit Description                       |
-- |                                                                                 |
-- | Parameters  : p_bank_account                                                    |
-- |               p_description                                                     |
-- |                                                                                 |
-- | Returns     : CHAR                                                              |
-- |                                                                                 |
-- |                                                                                 |
-- +=================================================================================+
FUNCTION get_provider_code ( p_bank_account      IN   ap_bank_accounts.bank_account_num%TYPE
                            ,p_description       IN   ce_statement_lines.trx_text%TYPE
                           )RETURN CHAR
IS
  -- -------------------------------------------
  -- Local Variable Decalration
  -- -------------------------------------------
  lc_provider     VARCHAR2(60);

BEGIN
  
  -- -------------------------------------------
  -- Get the Provider Code for Bank Account 
  -- '2090002608366'
  -- -------------------------------------------
  IF p_bank_account = '2090002608366' THEN 
  
    IF p_description LIKE '%TELECHECK%' THEN
      lc_provider := 'TELCHK' ;
    ELSIF p_description LIKE '%AMERICAN EXPRESS%' THEN
      lc_provider := 'AMXCRD' ; 
    ELSIF p_description LIKE '%5/3%' 
      OR p_description LIKE '%OFFICE DEPOT INC%' THEN
      lc_provider := 'MPSCRD' ; 
    ELSIF p_description LIKE '%TREASURY%' THEN
      lc_provider := 'CCSCRD' ;
    ELSE
      lc_provider := NULL;      
    END IF;    
    
  ELSE
    lc_provider := NULL; 
  END IF;
  -- -------------------------------------------
  -- Get the Provider Code for Bank Account 
  -- '280002000000299111'
  -- -------------------------------------------
  IF p_bank_account = '280002000000299111' THEN 
  
    IF p_description LIKE '%CITI%' THEN
      lc_provider := 'CCSCRD' ;
    ELSIF p_description LIKE '%AMEX BANK OF CANADA%' THEN
      lc_provider := 'AMXCRD' ;
    ELSE   
    lc_provider := NULL;    
    END IF;       
    
  ELSE
    lc_provider := NULL; 
  END IF;  
  
  RETURN lc_provider;
  
EXCEPTION
WHEN OTHERS THEN
-- FND_FILE.PUT_LINE(FND_FILE.LOG,'In exception block. Oracle error message = '||substr(sqlerrm,1,200));
  RETURN NULL;
  fnd_message.set_name ('XXFIN','XX_CE_001_UNEXPECTED');
  fnd_message.set_token('PACKAGE','XX_CE_AJB_CC_RECON_PKG.GET_PROVIDER_CODE');
  fnd_message.set_token('PROGRAM','Get Provider Code from Bank Description');
  fnd_message.set_token('SQLERROR',SQLERRM);
  FND_FILE.PUT_LINE(FND_FILE.LOG,'==========================');
  FND_FILE.PUT_LINE(FND_FILE.LOG,fnd_message.get);
END get_provider_code;    

-- +=================================================================================+
-- |                                                                                 |
-- |PROCEDURE                                                                        |
-- |  stmt_match_process                                                             |
-- |                                                                                 |
-- |DESCRIPTION                                                                      |
-- | Procedure to process for Match the Bank Statement and XX_CE_999 Interface       |
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
-- |  Submmit from Recon Process                                                     |
-- |                                                                                 |
-- |                                                                                 |
-- |                                                                                 |
-- +=================================================================================+ 
PROCEDURE  stmt_match_process 
                        (x_errbuf           OUT     NOCOPY VARCHAR2
                        ,x_retcode          OUT     NOCOPY NUMBER
                        ,p_email_id         IN             VARCHAR2  DEFAULT NULL                                                
                        )
IS                        

  -- -------------------------------------------
  -- Get all the Lockbox  Bank Statement Lines
  -- from CE statement header and lines tables
  -- -------------------------------------------
  CURSOR lcu_bnk_stmt_hdr_line   
  IS
  SELECT CSH.statement_header_id  
        ,CSH.bank_account_id
        ,CSH.statement_number
        ,CSH.statement_date
        ,NVL(CSH.currency_code,ABA.currency_code) currency_code
        ,CSH.attribute14
        ,CSH.attribute15
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
        ,CTC.trx_code
        ,(xx_ce_ajb_cc_recon_pkg.get_provider_code(ABA.bank_account_num,CSL.trx_text)) provider_code
  FROM   ce_statement_headers      CSH 
        ,ce_statement_lines        CSL
        ,ap_bank_accounts          ABA
        ,ce_transaction_codes      CTC
        ,fnd_lookup_values_vl      FLVL
  WHERE  CSH.statement_header_id    = CSL.statement_header_id   
  AND    CSH.bank_account_id        = ABA.bank_account_id
  --AND    ABA.bank_account_num       IN ('2090002608366','280002000000310000','280002000000299000','000280002000000299111')
  AND    CSL.trx_code_id            = CTC.transaction_code_id(+)
  AND    CTC.trx_code               IN('165 ','195','399') 
  AND    CTC.bank_account_id        = ABA.bank_account_id
  AND    FLVL.lookup_type           = 'OD_CREDIT_CARD_PROVIDERS'
  --AND    FLVL.lookup_code           = CSL.customer_text
  AND    FLVL.lookup_code           = xx_ce_ajb_cc_recon_pkg.get_provider_code(ABA.bank_account_num,CSL.trx_text)
  AND    NVL(FLVL.end_date_active ,SYSDATE + 1 ) > SYSDATE 
  AND    (CSL.status IS NULL 
       OR UPPER(CSL.status) = 'UNRECONCILED')
  AND    (CSL.attribute15 IS NULL 
       OR CSL.attribute15 NOT IN('PROCESSED-E1310'))
  AND    ABA.bank_account_type      = 'Corp - CC Settlements' 
  AND    NVL(ABA.inactive_date,SYSDATE + 1) > SYSDATE
  ORDER BY CSL.trx_date DESC;
  
  -- -------------------------------------------
  -- Get all the un-cleared record from
  -- XX_CE_999_INTERFACE table for matching 
  -- with bank statement
  -- -------------------------------------------
  CURSOR lcu_get_999_int_records (p_provider_type IN VARCHAR2)
  IS
  SELECT  XCE9.trx_id
         ,XCE9.trx_type
         ,XCE9.trx_number
         ,XCE9.trx_date
         ,XCE9.status
         ,XCE9.amount
         ,XCE9.record_type
         ,XCE9.ajb_file_number
         ,XCE9.rowid
  FROM    xx_ce_999_interface  XCE9
  WHERE   XCE9.status         = 'FLOAT'
  AND     XCE9.record_type    = p_provider_type
  AND     XCE9.vset_group_id  IS NULL
  AND     XCE9.statement_line_id IS NULL
  ORDER BY XCE9.trx_date DESC;

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

  -- -------------------------------------------
  -- Local Variable Declaration
  -- -------------------------------------------
  bnk_stmt_hdr_line_rec           lcu_bnk_stmt_hdr_line%ROWTYPE;
  get_999_int_records             lcu_get_999_int_records%ROWTYPE;
  
  lc_error_details                VARCHAR2(32000);  
  lc_error_location               VARCHAR2(4000); 
  lc_source_err_flag              VARCHAR2(1);
  lc_error                        VARCHAR2(32000);
  lc_match_flag                   VARCHAR2(1);
  
  ln_001_trx_code_id              NUMBER;
  ln_total_record                 NUMBER;
  ln_success_record               NUMBER;
  ln_retcode                      NUMBER;
  ln_mail_request_id              NUMBER;
  
  EX_STMT_MATCH_PROCESS           EXCEPTION;
  
BEGIN

  -- -------------------------------------------
  -- Initialize the Local Varaibles
  -- -------------------------------------------
  ln_001_trx_code_id    :=   NULL ;
  lc_source_err_flag    :=  'N';
  ln_total_record       :=   0;
  ln_success_record     :=   0;
  lc_match_flag         :=   NULL;
    
  -- -------------------------------------------
  -- Loop through all the un reconcilied records
  -- from bank
  -- -------------------------------------------
  OPEN lcu_bnk_stmt_hdr_line ;
  LOOP
  FETCH lcu_bnk_stmt_hdr_line INTO bnk_stmt_hdr_line_rec;
  EXIT WHEN lcu_bnk_stmt_hdr_line%NOTFOUND;
    
    -- ------------------------------------------------ 
    -- Get the Trx Code Id fo '001'
    -- ------------------------------------------------
    lc_error_location := 'Mandatory Check for Trx Code 001 for each bank account ';
    OPEN  lcu_get_001_trx_code ( p_bank_account  => bnk_stmt_hdr_line_rec.bank_account_id);
    FETCH lcu_get_001_trx_code INTO ln_001_trx_code_id;
    CLOSE lcu_get_001_trx_code;      

    -- -------------------------------------------
    -- Check wheather Trx Code '001' is set up or not
    -- -------------------------------------------
    IF ln_001_trx_code_id IS NULL THEN 
      lc_source_err_flag   := 'Y';   
      lc_error_details     := lc_error_details||'Trx Code is not setup for bank account:'||bnk_stmt_hdr_line_rec.bank_account_num||CHR(10);       
    END IF;     
    
    IF ln_001_trx_code_id IS NOT NULL THEN
      -- -------------------------------------------
      -- Loop through all the un-clear 999 interface 
      -- table and match amount with bank statement
      -- -------------------------------------------
      OPEN lcu_get_999_int_records (p_provider_type => bnk_stmt_hdr_line_rec.provider_code); 
      LOOP
      FETCH lcu_get_999_int_records INTO get_999_int_records;
      EXIT WHEN lcu_get_999_int_records%NOTFOUND;
      
        lc_match_flag   := NULL;
        ln_total_record := ln_total_record + 1;
        
      
        IF bnk_stmt_hdr_line_rec.amount = get_999_int_records.amount THEN
          -- -------------------------------------------
          -- Udpate the XX CE 999 Interface table 
          -- after matching the amount
          -- -------------------------------------------
          UPDATE xx_ce_999_interface XCE9
          SET   XCE9.vset_group_id             = bnk_stmt_hdr_line_rec.statement_line_id
              , XCE9.bank_trx_code_id_original = bnk_stmt_hdr_line_rec.bank_trx_number
              , XCE9.statement_header_id       = bnk_stmt_hdr_line_rec.statement_header_id
              , XCE9.statement_line_id         = bnk_stmt_hdr_line_rec.statement_line_id
              , XCE9.bank_account_id           = bnk_stmt_hdr_line_rec.bank_account_id
              , XCE9.currency_code             = bnk_stmt_hdr_line_rec.currency_code
          WHERE XCE9.record_type               = bnk_stmt_hdr_line_rec.provider_code 
          AND   XCE9.vset_group_id      IS NULL
          AND   XCE9.statement_line_id  IS NULL;
          
          -- -------------------------------------------
          -- Update the CSL Trx Code ID for 1295 processing
          -- -------------------------------------------
          UPDATE ce_statement_lines  CSL
          SET    CSL.trx_code_id        =  ln_001_trx_code_id
               , CSL.bank_trx_number    =  bnk_stmt_hdr_line_rec.trx_code_id
          WHERE  CSL.statement_line_id  =  bnk_stmt_hdr_line_rec.statement_line_id;  
          
          ln_success_record := ln_success_record + 1; 
          lc_match_flag     := 'Y' ;
          
        END IF;

        -- -------------------------------------------          
        -- Print the Process Detail of the records
        -- -------------------------------------------
        lc_error_location := 'Calling the Printing Detail Report';
        print_match_summary
                           (x_errbuf                 =>  lc_error
                           ,x_retcode                =>  ln_retcode
                           ,p_total                  =>  NULL
                           ,p_toal_match             =>  NULL
                           ,p_match_request_id       =>  gn_match_request_id
                           ,p_processor_id           =>  get_999_int_records.record_type 
                           ,p_statement_number       =>  bnk_stmt_hdr_line_rec.statement_number
                           ,p_statement_line_number  =>  bnk_stmt_hdr_line_rec.line_number
                           ,p_message                =>  lc_match_flag
                           ,p_print_option           =>  'DETAIL'
                           );
                               
        IF ln_retcode = gn_error THEN 
          lc_error_details := lc_error_details||lc_error;
          RAISE EX_STMT_MATCH_PROCESS;        
        END IF;     
        
      END LOOP ;
      CLOSE lcu_get_999_int_records;
    END IF;
  END LOOP;
  CLOSE lcu_bnk_stmt_hdr_line;
  -- -------------------------------------------          
  -- Print the Process Detail of the records
  -- -------------------------------------------
  lc_error_location := 'Calling the Printing Detail Report';
  print_match_summary
                     (x_errbuf                 =>  lc_error
                     ,x_retcode                =>  ln_retcode
                     ,p_total                  =>  ln_total_record
                     ,p_toal_match             =>  ln_success_record
                     ,p_match_request_id       =>  gn_match_request_id
                     ,p_processor_id           =>  NULL
                     ,p_statement_number       =>  NULL
                     ,p_statement_line_number  =>  NULL
                     ,p_message                =>  NULL
                     ,p_print_option           =>  'SUMMARY'
                     );    
                     
  IF ln_retcode = gn_error THEN 
    lc_error_details := lc_error_details||lc_error;
    RAISE EX_STMT_MATCH_PROCESS;        
  END IF;                      
  
  COMMIT;  
  
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
                                            ,argument3   => 'AJB Statement Match Process - ' ||TRUNC(SYSDATE)
                                            ,argument4   => ''
                                            ,argument5   => 'Y'
                                            ,argument6   => gn_match_request_id                                            
                                            );
    COMMIT;
  
  
    IF ln_mail_request_id IS NULL OR ln_mail_request_id = 0 THEN     
      lc_error_location := 'Failed to submit the Standard Common Emailer Program';    
      RAISE EX_STMT_MATCH_PROCESS;
    END IF;  
  END IF;  

EXCEPTION
WHEN EX_STMT_MATCH_PROCESS THEN 
  x_errbuf   := lc_error_location||'-'||lc_error_details;
  x_retcode  := gn_error;       
  FND_FILE.PUT_LINE(FND_FILE.LOG,'==========================');
  FND_FILE.PUT_LINE(FND_FILE.LOG,x_errbuf);    
WHEN OTHERS THEN
  ROLLBACK;    
  fnd_message.set_name ('XXFIN','XX_CE_001_UNEXPECTED');  
  fnd_message.set_token('PACKAGE','XX_CE_LOCKBOX_RECON_PKG.stmt_match_process');
  fnd_message.set_token('PROGRAM','CE Bank Statement Matching process');
  fnd_message.set_token('SQLERROR',SQLERRM);
  x_errbuf   := lc_error_location||'-'||lc_error_details||'-'||fnd_message.get;
  x_retcode  := gn_error;       
  FND_FILE.PUT_LINE(FND_FILE.LOG,'==========================');
  FND_FILE.PUT_LINE(FND_FILE.LOG,x_errbuf);  

END stmt_match_process;

END XX_CE_AJB_CC_RECON_PKG;
/
SHOW ERRORS;
EXIT;

-- -------------------------------------------------------------------
-- End of Script                                                   
-- -------------------------------------------------------------------


