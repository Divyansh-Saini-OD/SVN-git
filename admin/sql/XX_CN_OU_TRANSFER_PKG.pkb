CREATE OR REPLACE PACKAGE BODY XX_CN_OU_TRANSFER_PKG AS
-- +================================================================================+
-- |                  Office Depot - Project Simplify                               |
-- |                Oracle NAIO Consulting Organization                             |
-- +================================================================================+
-- | Name       : XX_CN_OU_TRANSFER_PKG                                             |
-- |                                                                                |
-- | Rice ID    : E0605_PostCollectionProcess                                       |
-- | Description: Package body to extract and transfer the eligible lines between   |
-- |              xx_cn_sum_trx and xx_cn_ou_trnsfr tables.                         |
-- |                                                                                |
-- |                                                                                |
-- |Change Record:                                                                  |
-- |===============                                                                 |
-- |Version   Date         Author                 Remarks                           |
-- |========  ===========  =============          ===============================   |
-- |DRAFT 1A  18-OCT-2007  Hema Chikkanna         Initial draft version             |
-- |1.0       19-OCT-2007  Hema Chikkanna         Incorporated changes After TL's   |
-- |                                              Review.                           |
-- |                                                                                |
-- |1.1       07-NOV-2007  Hema Chikkanna         Incorporated changes for LOG Error|
-- |                                                                                |
-- |1.2       13-NOV-2007  Hema Chikkanna         Incorporated changes for LOG Error|
-- +================================================================================+

   -- Global constants
   G_STG_STATUS     CONSTANT VARCHAR2(30)  := 'STAGED';
   G_ELIGIBLE       CONSTANT VARCHAR2(30)  := 'ELIGIBLE';
   G_NOT_ELIGIBLE   CONSTANT VARCHAR2(30)  := 'NOT-ELIGIBLE';
   G_TRANSFERRED    CONSTANT VARCHAR2(30)  := 'TRANSFERRED';
   
   G_CONV_TYPE      CONSTANT VARCHAR2(30)  := 'Ending Rate';
   
   G_TRX_TYPE       CONSTANT VARCHAR2(30)  := 'OU_TRANSFER'; 
   G_PROG_TYPE      CONSTANT VARCHAR2(100) := 'E0605_PostCollectionProcess';
   
   -- Global Variables
   gn_client_org_id          PLS_INTEGER   := FND_GLOBAL.ORG_ID;


-- +==============================================================+
-- | Name        : OU_TRANSFER_MAIN                               |
-- |                                                              |
-- | Description : Procedure to extract and transfer the eligible |
-- |               lines between xx_cn_sum_trx and xx_cn_ou_trnsfr|
-- |               tables.                                        |
-- |                                                              |
-- | Parameters  : x_errbuf         OUT   VARCHAR2                |
-- |               x_retcode        OUT   NUMBER                  |
-- |                                                              |
-- +==============================================================+


PROCEDURE ou_transfer_main  ( x_errbuf      OUT NOCOPY VARCHAR2
                             ,x_retcode     OUT NOCOPY NUMBER
                            ) IS

ln_insert_count            PLS_INTEGER := 0;
ln_update_count            PLS_INTEGER := 0;
lc_error_message           VARCHAR2(4000);


lc_process_type            VARCHAR2(40);
ln_proc_sum_audit_id       NUMBER;
ln_proc_trnsfr_audit_id    NUMBER;
lc_descritpion             VARCHAR2(4000);

ln_code                    NUMBER;
lc_message                 VARCHAR2(4000);

L_COLL_ELGBLE              CONSTANT VARCHAR2(1) := 'Y';



-- Standard who columns
ln_created_by              NUMBER         := FND_GLOBAL.user_id;
ld_creation_date           DATE           := SYSDATE;
ln_last_updated_by         NUMBER         := FND_GLOBAL.user_id;
ld_last_update_date        DATE           := SYSDATE;
ln_last_update_login       NUMBER         := FND_GLOBAL.login_id;
ln_request_id              NUMBER         := FND_GLOBAL.conc_request_id;
ln_prog_appl_id            NUMBER         := FND_GLOBAL.prog_appl_id;


BEGIN

    ln_code     := NULL;
    lc_message  := NULL;
    
    xx_cn_util_pkg.display_out ('******************** POST Collections (OU Transfer) ********************');
    xx_cn_util_pkg.display_out ('');
    xx_cn_util_pkg.display_out ('********************************* BEGIN *********************************');
    xx_cn_util_pkg.display_out ('');

    xx_cn_util_pkg.display_log ('******************** POST Collections (OU Transfer) ********************');
    xx_cn_util_pkg.display_log ('');
    xx_cn_util_pkg.display_log ('********************************* BEGIN *********************************');
    xx_cn_util_pkg.display_log ('');
    
    -----------------------------------------------  
    -- Main extraction process from XX_CN_SUM_TRX
    -----------------------------------------------
        
    lc_process_type      := 'OU_TRNSFR_1';
    
    ln_proc_sum_audit_id := NULL;  -- Will get a value in the call below

    lc_descritpion       := 'OU Transfer: Begin of the extract process from xx_cn_sum_trx table';

    xx_cn_util_pkg.begin_batch(
                                p_parent_proc_audit_id  => NULL
                               ,x_process_audit_id      => ln_proc_sum_audit_id
                               ,p_request_id            => fnd_global.conc_request_id
                               ,p_process_type          => lc_process_type
                               ,p_description           => lc_descritpion
                              );

    xx_cn_util_pkg.DEBUG('Post Collections: OU Transfer>>');

    BEGIN
           
          xx_cn_util_pkg.display_out ('Inserting the eligible lines from Summarized table to OU Transfer Table');
          xx_cn_util_pkg.display_out ('-----------------------------------------------------------------------');
          xx_cn_util_pkg.display_out (' ');
          -- Initializing the variables
          ln_insert_count := 0;
          ln_update_count := 0;
          lc_error_message := NULL;
          ln_code          := NULL;
          lc_message       := NULL;
          
          xx_cn_util_pkg.DEBUG('OU Transfer: Inserting records into XX_CN_OU_TRNSFR'); 
          --------------------------------------------------------------
          -- Inserting the eligible lines from xx_cn_sum_trx
          -- to xx_cn_ou_trnsfr for OU Transfer
          -- The OU_TRANSFER_STATUS on XX_CN_SUM_TRX table is populated
          -- by Summarization object. So addtional check for eligible lines
          -- is not covered in this object. 
          ---------------------------------------------------------------
          
          INSERT INTO xx_cn_ou_trnsfr XCOT ( 
                        XCOT.ou_trnsfr_id              
                       ,XCOT.salesrep_id               
                       ,XCOT.rollup_date               
                       ,XCOT.revenue_class_id          
                       ,XCOT.revenue_type              
                       ,XCOT.org_id                    
                       ,XCOT.resource_org_id           
                       ,XCOT.division                  
                       ,XCOT.salesrep_division         
                       ,XCOT.role_id                   
                       ,XCOT.comp_group_id 
                       ,XCOT.processed_date
                       ,XCOT.processed_period_id       
                       ,XCOT.transaction_amount        
                       ,XCOT.trx_type                  
                       ,XCOT.quantity                  
                       ,XCOT.transaction_currency_code 
                       ,XCOT.exchange_rate             
                       ,XCOT.discount_percentage       
                       ,XCOT.margin                    
                       ,XCOT.salesrep_number           
                       ,XCOT.rollup_flag               
                       ,XCOT.source_doc_type           
                       ,XCOT.object_version_number     
                       ,XCOT.ou_transfer_status
                       ,XCOT.attribute1                
                       ,XCOT.attribute2                
                       ,XCOT.attribute3                
                       ,XCOT.attribute4                
                       ,XCOT.attribute5                
                       ,XCOT.conc_batch_id             
                       ,XCOT.process_audit_id          
                       ,XCOT.request_id                
                       ,XCOT.program_application_id    
                       ,XCOT.created_by                
                       ,XCOT.creation_date             
                       ,XCOT.last_updated_by           
                       ,XCOT.last_update_date          
                       ,XCOT.last_update_login
                      )  (SELECT 
                        xx_cn_ou_trnsfr_s.NEXTVAL 
                       ,XCSTV.salesrep_id               
                       ,XCSTV.rollup_date               
                       ,XCSTV.revenue_class_id          
                       ,XCSTV.revenue_type              
                       ,XCSTV.resource_org_id           
                       ,XCSTV.resource_org_id           
                       ,XCSTV.division                  
                       ,XCSTV.salesrep_division         
                       ,XCSTV.role_id                   
                       ,XCSTV.comp_group_id 
                       ,XCSTV.processed_date
                       ,XCSTV.processed_period_id       
                       ,(XCSTV.transaction_amount * GDR.conversion_rate)        
                       ,G_TRX_TYPE                  
                       ,XCSTV.quantity                  
                       ,GSOB.currency_code 
                       ,GDR.conversion_rate             
                       ,(XCSTV.discount_percentage * GDR.conversion_rate)      
                       ,(XCSTV.margin * GDR.conversion_rate)                   
                       ,XCSTV.salesrep_number           
                       ,XCSTV.rollup_flag               
                       ,XCSTV.source_doc_type           
                       ,XCSTV.object_version_number     
                       ,G_STG_STATUS        
                       ,XCSTV.attribute1                
                       ,XCSTV.attribute2                
                       ,XCSTV.attribute3                
                       ,XCSTV.attribute4                
                       ,XCSTV.attribute5                
                       ,NULL
                       ,ln_proc_sum_audit_id
                       ,ln_request_id
                       ,ln_prog_appl_id
                       ,ln_created_by        
                       ,ld_creation_date     
                       ,ln_last_updated_by   
                       ,ld_last_update_date  
                       ,ln_last_update_login 
               FROM     xx_cn_sum_trx_v           XCSTV,
                        gl_daily_rates            GDR,
                        gl_daily_conversion_types GDCT,
                        gl_sets_of_books          GSOB,
                        cn_repositories_all       CRA
               WHERE    GDR.conversion_type           = GDCT.conversion_type
               AND      GDCT.user_conversion_type     = G_CONV_TYPE 
               AND      GDR.conversion_date           = TRUNC(XCSTV.rollup_date)
               AND      GDR.from_currency             = XCSTV.transaction_currency_code
               AND      CRA.org_id                    = XCSTV.resource_org_id
               AND      CRA.set_of_books_id           = GSOB.set_of_books_id
               AND      GDR.to_currency               = GSOB.currency_code
               AND      XCSTV.ou_transfer_status      = G_ELIGIBLE);
               
               xx_cn_util_pkg.DEBUG('OU Transfer: End of inserting records into XX_CN_OU_TRNSFR');
               
               ln_insert_count := SQL%ROWCOUNT;
                              
               lc_error_message := 'OU Transfer: Number of records inserted into XX_CN_OU_TRNSFR table: '||ln_insert_count;
               
               xx_cn_util_pkg.display_out (lc_error_message);
               
               xx_cn_util_pkg.display_out (' '); 
  
               -------------------------------------------------------------
               -- Update the extracted records status of XX_CN_SUM_TRX table
               -- to Transferred 
               -------------------------------------------------------------
               xx_cn_util_pkg.DEBUG('OU Transfer: Updating the OU transfer status of XX_CN_SUM_TRX'); 
               
               UPDATE xx_cn_sum_trx_v XCST
               SET    XCST.ou_transfer_status = G_TRANSFERRED
                     ,XCST.collect_eligible   = 'N'   
                     ,XCST.last_updated_by    = ln_last_updated_by  
                     ,XCST.last_update_date   = ld_last_update_date 
                     ,XCST.last_update_login  = ln_last_update_login
               WHERE  XCST.ou_transfer_status = G_ELIGIBLE;
               
               xx_cn_util_pkg.DEBUG('OU Transfer: End of updating the OU transfer status of XX_CN_SUM_TRX'); 
               
               ln_update_count := SQL%ROWCOUNT;
               
               lc_error_message := 'OU Transfer: Number of records updated in XX_CN_SUM_TRX table: '||ln_update_count;
               
               xx_cn_util_pkg.update_batch(
                                            p_process_audit_id      => ln_proc_sum_audit_id
                                           ,p_execution_code        => 0
                                           ,p_error_message         => lc_error_message
                                          );

               
               xx_cn_util_pkg.end_batch   (ln_proc_sum_audit_id);
               
               xx_cn_util_pkg.display_out (lc_error_message);
               
               xx_cn_util_pkg.display_out (' '); 
               
               COMMIT;
                      
    EXCEPTION
        
         WHEN OTHERS THEN
                        
              RAISE;
    END;                 
    
    -------------------------------------------------  
    -- Extraction process from XX_CN_OU_TRNSFR table
    -------------------------------------------------

    lc_process_type      := 'OU_TRNSFR_2';

    ln_proc_sum_audit_id := NULL;  -- Will get a value in the call below

    lc_descritpion       := 'OU Transfer: Begin of the extract process from xx_cn_ou_trnsfr table';

    xx_cn_util_pkg.begin_batch(
                                p_parent_proc_audit_id  => NULL
                               ,x_process_audit_id      => ln_proc_trnsfr_audit_id
                               ,p_request_id            => fnd_global.conc_request_id
                               ,p_process_type          => lc_process_type
                               ,p_description           => lc_descritpion
                              );

    BEGIN
        
        xx_cn_util_pkg.display_out ('Inserting the eligible lines from OU Transfer table to Summarized Table');
        xx_cn_util_pkg.display_out ('-----------------------------------------------------------------------');
        xx_cn_util_pkg.display_out (' ');
        
        -- Initializing the variables
        ln_insert_count := 0; 
        lc_error_message := NULL; 
        ln_code          := NULL; 
        lc_message       := NULL;
        
        
        xx_cn_util_pkg.DEBUG('OU Transfer: Inserting records into XX_CN_SUM_TRX'); 
        -----------------------------------------------------
        -- Inserting the eligible lines from xx_cn_ou_trnsfr
        -- to xx_cn_sum_trx for OU Transfer
        -----------------------------------------------------
        INSERT INTO xx_cn_sum_trx XCST ( 
                      XCST.sum_trx_id                         
                     ,XCST.salesrep_id                        
                     ,XCST.rollup_date                        
                     ,XCST.revenue_class_id                   
                     ,XCST.revenue_type                       
                     ,XCST.org_id                             
                     ,XCST.resource_org_id                    
                     ,XCST.division                           
                     ,XCST.salesrep_division                  
                     ,XCST.role_id                            
                     ,XCST.comp_group_id                      
                     ,XCST.processed_date                     
                     ,XCST.processed_period_id                
                     ,XCST.transaction_amount                 
                     ,XCST.trx_type                           
                     ,XCST.quantity                           
                     ,XCST.transaction_currency_code          
                     ,XCST.exchange_rate                      
                     ,XCST.discount_percentage                
                     ,XCST.margin                             
                     ,XCST.salesrep_number                    
                     ,XCST.rollup_flag                        
                     ,XCST.source_doc_type                    
                     ,XCST.object_version_number              
                     ,XCST.ou_transfer_status                 
                     ,XCST.collect_eligible                   
                     ,XCST.attribute1                         
                     ,XCST.attribute2                         
                     ,XCST.attribute3                         
                     ,XCST.attribute4                         
                     ,XCST.attribute5                         
                     ,XCST.conc_batch_id                      
                     ,XCST.process_audit_id                   
                     ,XCST.request_id                         
                     ,XCST.program_application_id             
                     ,XCST.created_by                         
                     ,XCST.creation_date                      
                     ,XCST.last_updated_by                    
                     ,XCST.last_update_date                   
                     ,XCST.last_update_login                  
                    ) (SELECT 
                      xx_cn_sum_trx_s.NEXTVAL          
                     ,XCOTV.salesrep_id                   
                     ,XCOTV.rollup_date                   
                     ,XCOTV.revenue_class_id              
                     ,XCOTV.revenue_type                  
                     ,XCOTV.org_id                                 
                     ,XCOTV.resource_org_id               
                     ,XCOTV.division                      
                     ,XCOTV.salesrep_division             
                     ,XCOTV.role_id                       
                     ,XCOTV.comp_group_id             
                     ,XCOTV.processed_date            
                     ,XCOTV.processed_period_id           
                     ,XCOTV.transaction_amount            
                     ,XCOTV.trx_type                      
                     ,XCOTV.quantity                      
                     ,XCOTV.transaction_currency_code 
                     ,XCOTV.exchange_rate                 
                     ,XCOTV.discount_percentage           
                     ,XCOTV.margin                        
                     ,XCOTV.salesrep_number               
                     ,XCOTV.rollup_flag                   
                     ,XCOTV.source_doc_type               
                     ,XCOTV.object_version_number         
                     ,G_NOT_ELIGIBLE        
                     ,L_COLL_ELGBLE              
                     ,XCOTV.attribute1                    
                     ,XCOTV.attribute2                    
                     ,XCOTV.attribute3                    
                     ,XCOTV.attribute4                
                     ,XCOTV.attribute5 
                     ,NULL
                     ,ln_proc_trnsfr_audit_id
                     ,ln_request_id
                     ,ln_prog_appl_id
                     ,ln_created_by        
                     ,ld_creation_date     
                     ,ln_last_updated_by   
                     ,ld_last_update_date  
                     ,ln_last_update_login 
             FROM     xx_cn_ou_trnsfr_v         XCOTV
             WHERE    XCOTV.ou_transfer_status  = G_STG_STATUS);

             xx_cn_util_pkg.DEBUG('OU Transfer: End of inserting records into XX_CN_SUM_TRX ');
             
             ln_insert_count := SQL%ROWCOUNT;
             
             lc_error_message := 'OU Transfer: Number of records inserted into XX_CN_SUM_TRX table: '||ln_insert_count;
             
             xx_cn_util_pkg.display_out (lc_error_message);
             
             xx_cn_util_pkg.display_out (' '); 
 
             -------------------------------------------------------------
             -- Update the extracted records status of XX_CN_SUM_TRX table
             -- to Transferred 
             -------------------------------------------------------------
             xx_cn_util_pkg.DEBUG('OU Transfer: Updating the OU transfer status of XX_CN_OU_TRNSFR'); 

             UPDATE xx_cn_ou_trnsfr_v XCOT
             SET    XCOT.ou_transfer_status = G_TRANSFERRED
                   ,XCOT.last_updated_by    = ln_last_updated_by  
                   ,XCOT.last_update_date   = ld_last_update_date 
                   ,XCOT.last_update_login  = ln_last_update_login
             WHERE  XCOT.ou_transfer_status = G_STG_STATUS;

             xx_cn_util_pkg.DEBUG('OU Transfer: End of updating the OU transfer status of XX_CN_OU_TRNSFR'); 

             ln_update_count := SQL%ROWCOUNT;

             lc_error_message := 'OU Transfer: Number of records updated in XX_CN_OU_TRNSFR table: '||ln_update_count;
             
             
             
             xx_cn_util_pkg.update_batch(
                                          p_process_audit_id      => ln_proc_trnsfr_audit_id
                                         ,p_execution_code        => 0
                                         ,p_error_message         => lc_error_message
                                        );


             xx_cn_util_pkg.end_batch   (ln_proc_trnsfr_audit_id);

             

             xx_cn_util_pkg.display_out (lc_error_message);
             xx_cn_util_pkg.display_out (' '); 

             COMMIT;
             
             xx_cn_util_pkg.DEBUG('Post Collections: OU Transfer<<');

    EXCEPTION
        
        WHEN OTHERS THEN
        
              RAISE;  

    END;
   
   x_retcode := 0;
   
   
   xx_cn_util_pkg.display_out ('********************************* End *********************************');
   xx_cn_util_pkg.display_out ('');
   
   xx_cn_util_pkg.display_log ('********************************* End *********************************');
   xx_cn_util_pkg.display_log ('');
    
                     
EXCEPTION 
   
     WHEN OTHERS THEN

            ROLLBACK;

            ln_code := -1;

            FND_MESSAGE.set_name  ('XXCRM', 'XX_OIC_0010_UNEXPECTED_ERR');
            FND_MESSAGE.set_token ('SQL_CODE', SQLCODE);
            FND_MESSAGE.set_token ('SQL_ERR',  SQLERRM);

            lc_message := fnd_message.get;

            xx_cn_util_pkg.log_error ( p_prog_name      => 'XX_CN_OU_TRANSFER_PKG.OU_TRANSFER_MAIN'
                                      ,p_prog_type      => G_PROG_TYPE
                                      ,p_prog_id        => ln_request_id 
                                      ,p_exception      => 'XX_CN_OU_TRANSFER_PKG.OU_TRANSFER_MAIN' -- changes made on 13-NOV-2007
                                      ,p_message        => lc_message
                                      ,p_code           => ln_code
                                      ,p_err_code       => 'XX_OIC_0010_UNEXPECTED_ERR'
                                     );


            xx_cn_util_pkg.DEBUG (lc_message); 

            xx_cn_util_pkg.display_log (lc_message);
            
            
            
            IF ln_proc_sum_audit_id IS NOT NULL THEN 
            
                  xx_cn_util_pkg.update_batch(
                                               p_process_audit_id      => ln_proc_sum_audit_id
                                              ,p_execution_code        => SQLCODE
                                              ,p_error_message         => lc_message
                                             );


                  xx_cn_util_pkg.end_batch (ln_proc_sum_audit_id);

            END IF;
            
            IF ln_proc_trnsfr_audit_id IS NOT NULL THEN 

               xx_cn_util_pkg.update_batch(
                                            p_process_audit_id      => ln_proc_trnsfr_audit_id
                                           ,p_execution_code        => SQLCODE
                                           ,p_error_message         => lc_message
                                          );


               xx_cn_util_pkg.end_batch (ln_proc_trnsfr_audit_id);
            
            END IF;

            xx_cn_util_pkg.display_log ('*************************** END OF PROCESS ******************************');

            xx_cn_util_pkg.display_out ('*************************** END OF PROCESS ******************************');

            x_retcode := 2;

            x_errbuf := 'Procedure: OU_TRANSFER_MAIN: ' || lc_message;             
                      
END ou_transfer_main;

END XX_CN_OU_TRANSFER_PKG;
/

SHOW ERRORS


EXIT;