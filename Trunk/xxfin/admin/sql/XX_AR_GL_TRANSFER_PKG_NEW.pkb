 SET SHOW OFF
 SET VERIFY OFF
 SET ECHO OFF
 SET TAB OFF 
 SET FEEDBACK OFF
 SET TERM ON  

 PROMPT Creating Package Body XX_AR_GL_TRANSFER_PKG_NEW
 PROMPT Program exits if the creation is not successful
 WHENEVER SQLERROR CONTINUE

 CREATE OR REPLACE
 PACKAGE BODY XX_AR_GL_TRANSFER_PKG_NEW
 AS
 -- +===================================================================+
 -- |                  Office Depot - Project Simplify                  |
 -- |                       WIPRO Technologies                          |
 -- +===================================================================+
 -- | Name :    XX_AR_GL_TRANSFER_PKG                                   |
 -- | RICE :    E2015                                                   |
 -- | Description : This package is used to submit the General Ledger   |
 -- |               transfer program for AR                             |
 -- |Change Record:                                                     |
 -- |===============                                                    |
 -- |Version   Date          Author              Remarks                |
 -- |=======   ==========   =============        =======================|
 -- |1.0       14-OCT-08    Aravind A            Initial version        |
 -- +===================================================================+

 -- +===================================================================+
 -- | Name        : SUBMIT_PROGRAM                                      |
 -- | Description : The procedure is used to accomplish the following   |
 -- |               tasks:                                              |
 -- |               1. Submit the General Ledger Transfer Program       |
 -- |               2. Submit the OD Receivables Multithread            |
 -- |                  General Ledger Journal Import program            |
 -- |               3. Log the details about the GL Transfer program    |
 -- |                  to the custom table XX_FIN_PROGRAM_STATS         |
 -- |                                                                   |
 -- | Parameters  : p_start_date                                        |
 -- |               ,p_post_through_date                                |
 -- |               ,p_gl_posted_date                                   |
 -- |               ,p_post_in_summary                                  |
 -- |               ,p_run_journal_imp                                  |
 -- |               ,p_transaction_type                                 |
 -- |               ,p_wave_num                                         |
 -- |               ,p_run_date                                         |
 -- |               ,p_child_to_xptr                                    |
 -- |               ,p_batch_size                                       |
 -- |               ,p_max_wait_int                                     |
 -- |               ,p_max_wait_time                                    |
 -- |               ,p_email_id                                         |
 -- |                                                                   |
 -- | Returns     : x_error_buff                                        |
 -- |               ,x_ret_code                                         |
 -- +===================================================================+

    gc_receivables           VARCHAR2(25)            DEFAULT  'Receivables';

    PROCEDURE SUBMIT_PROGRAM(
                             x_error_buff            OUT      VARCHAR2                    
                             ,x_ret_code             OUT      NUMBER                      
                             ,p_start_date           IN       VARCHAR2                    
                             ,p_post_through_date    IN       VARCHAR2                    
                             ,p_gl_posted_date       IN       VARCHAR2                    
                             ,p_post_in_summary      IN       VARCHAR2                    
                             ,p_run_journal_imp      IN       VARCHAR2                    
                             ,p_transaction_type     IN       VARCHAR2                    
                             ,p_wave_num             IN       NUMBER                      
                             ,p_run_date             IN       VARCHAR2                    
                             ,p_child_to_xptr        IN       VARCHAR2                    
                             ,p_batch_size           IN       NUMBER                      
                             ,p_max_wait_int         IN       PLS_INTEGER     
                             ,p_max_wait_time        IN       PLS_INTEGER   
                             ,p_email_id             IN       VARCHAR2
                            )
    IS
       ln_gl_trf_req_id          fnd_concurrent_requests.request_id%TYPE                 := 0;
       ln_rec_multi_req_id       fnd_concurrent_requests.request_id%TYPE                 := 0;
       ln_conc_prog_id           fnd_concurrent_requests.concurrent_program_id%TYPE      := 0;
       ln_application_id         fnd_concurrent_requests.program_application_id%TYPE     := 0;
       ln_request_id             fnd_concurrent_requests.request_id%TYPE                 := 0;
       ln_par_req_id             fnd_concurrent_requests.parent_request_id%TYPE          := 0;
       lc_req_state              fnd_concurrent_requests.status_code%TYPE                := NULL;
       ld_req_date               fnd_concurrent_requests.request_date%TYPE               := NULL;
       ld_act_strt_date          fnd_concurrent_requests.actual_start_date%TYPE          := NULL;
       ld_act_comp_date          fnd_concurrent_requests.actual_completion_date%TYPE     := NULL;
       lc_sob_name               gl_sets_of_books.name%TYPE                              := NULL;
       lc_currency               gl_interface.currency_code%TYPE                         := NULL;
       ln_count                  NUMBER                                                  := 0;
       ln_total_cr               gl_interface.entered_cr%TYPE                            := 0;
       ln_total_dr               gl_interface.entered_dr%TYPE                            := 0;
       ln_group_id               gl_interface.group_id%TYPE                              := 0;
       lc_error_loc              VARCHAR2(200)                                           := NULL;
       lc_object_type            xx_com_error_log.object_type%TYPE                       := 'AR to GL Transfer';
       ln_object_id              xx_com_error_log.object_id%TYPE                         := 0;
       lc_error_msg              xx_com_error_log.error_message%TYPE                     := 0;
       ld_start_date             DATE                                                    := NULL;
       ld_post_through_date      DATE                                                    := NULL;
       ld_gl_posted_date         DATE                                                    := NULL;
       ld_run_date               DATE                                                    := NULL;
       lb_req_status             BOOLEAN                                                 := NULL;
       lc_phase                  VARCHAR2(50)                                            := NULL;
       lc_status                 VARCHAR2(50)                                            := NULL;
       lc_devphase               VARCHAR2(50)                                            := NULL;
       lc_devstatus              VARCHAR2(50)                                            := NULL;
       lc_message                VARCHAR2(50)                                            := NULL;
       lb_req_status_mul         BOOLEAN                                                 := NULL;
       lc_phase_mul              VARCHAR2(50)                                            := NULL;
       lc_status_mul             VARCHAR2(50)                                            := NULL;
       lc_devphase_mul           VARCHAR2(50)                                            := NULL;
       lc_devstatus_mul          VARCHAR2(50)                                            := NULL;
       lc_message_mul            VARCHAR2(50)                                            := NULL;
       ln_posting_days           ar_system_parameters.posting_days_per_cycle%TYPE        := NULL;
       lc_debug_mode             fnd_lookups.meaning%TYPE                                := NULL;
       ln_org_id                 ar_system_parameters.org_id%TYPE                        := NULL;
       ln_set_of_books_id        ar_system_parameters.set_of_books_id%TYPE               := NULL;
       ln_multi_ro_mail_req_id   fnd_concurrent_requests.request_id%TYPE                 := 0;
       ln_gltp_ro_mail_req_id    fnd_concurrent_requests.request_id%TYPE                 := 0;
       ln_max_wait_int           NUMBER                                                  := 0;
       ln_max_wait_time          NUMBER                                                  := 0;


    BEGIN
       --Submit the General Ledger Transfer Program with
       --the supplied parameters.
       FND_FILE.PUT_LINE(FND_FILE.LOG,'**********************************OD: AR General Ledger Transfer Program**********************************');
       FND_FILE.PUT_LINE(FND_FILE.LOG,'Parameters of the current Request:');
       FND_FILE.PUT_LINE(FND_FILE.LOG,'p_start_date           : '||p_start_date);           
       FND_FILE.PUT_LINE(FND_FILE.LOG,'p_post_through_date    : '||p_post_through_date);
       FND_FILE.PUT_LINE(FND_FILE.LOG,'p_gl_posted_date       : '||p_gl_posted_date);   
       FND_FILE.PUT_LINE(FND_FILE.LOG,'p_post_in_summary      : '||p_post_in_summary);
       FND_FILE.PUT_LINE(FND_FILE.LOG,'p_run_journal_imp      : '||p_run_journal_imp);  
       FND_FILE.PUT_LINE(FND_FILE.LOG,'p_transaction_type     : '||p_transaction_type); 
       FND_FILE.PUT_LINE(FND_FILE.LOG,'p_wave_num             : '||p_wave_num);
       FND_FILE.PUT_LINE(FND_FILE.LOG,'p_run_date             : '||p_run_date);         
       FND_FILE.PUT_LINE(FND_FILE.LOG,'p_child_to_xptr        : '||p_child_to_xptr);    
       FND_FILE.PUT_LINE(FND_FILE.LOG,'p_batch_size           : '||p_batch_size);       
       FND_FILE.PUT_LINE(FND_FILE.LOG,'p_max_wait_int         : '||p_max_wait_int);     
       FND_FILE.PUT_LINE(FND_FILE.LOG,'p_max_wait_time        : '||p_max_wait_time);    
       FND_FILE.PUT_LINE(FND_FILE.LOG,'**********************************************************************************************************');

       lc_error_loc := 'Converting the date parameters';
       ld_start_date        := FND_DATE.CANONICAL_TO_DATE(p_start_date);
       ld_post_through_date := FND_DATE.CANONICAL_TO_DATE(p_post_through_date);
       ld_gl_posted_date    := FND_DATE.CANONICAL_TO_DATE(p_gl_posted_date);   
       ld_run_date          := FND_DATE.CANONICAL_TO_DATE(p_run_date);  
       ln_max_wait_int      := NVL(p_max_wait_int,60);
       ln_max_wait_time     := NVL(p_max_wait_time,36000);

       SELECT posting_days_per_cycle
       INTO   ln_posting_days
       FROM   ar_system_parameters;

       SELECT meaning
       INTO   lc_debug_mode
       FROM   fnd_lookups
       WHERE  lookup_type = 'YES_NO' 
       AND    lookup_code = 'Y';

       SELECT org_id
       INTO   ln_org_id
       FROM   ar_system_parameters;

       SELECT set_of_books_id
       INTO   ln_set_of_books_id
       FROM   ar_system_parameters;

       lc_error_loc := 'Submitting the General Ledger Transfer Program';
       ln_gl_trf_req_id := FND_REQUEST.SUBMIT_REQUEST(
                                                      'AR'
                                                      ,'ARGLTP'
                                                      ,NULL
                                                      ,NULL
                                                      ,FALSE
                                                      ,TO_CHAR(ld_start_date,'YYYY/MM/DD HH:MI:SS')
                                                      ,TO_CHAR(ld_post_through_date,'YYYY/MM/DD HH:MI:SS')
                                                      ,TO_CHAR(ld_gl_posted_date,'YYYY/MM/DD HH:MI:SS') 
                                                      ,'N'
                                                      ,p_post_in_summary  
                                                      ,p_run_journal_imp 
                                                      ,ln_posting_days
                                                      ,-99
                                                      ,lc_debug_mode
                                                      ,ln_org_id
                                                      ,ln_set_of_books_id
                                                      ,p_transaction_type 
                                                     );

       COMMIT;

       FND_FILE.PUT_LINE(FND_FILE.LOG,'General Ledger Transfer Program has been submitted with Request ID :'||ln_gl_trf_req_id);

       IF (ln_gl_trf_req_id <> 0) THEN
          
          --Wait till the GL Transfer program has transferred
          --the transaction details to GL Interface table
          lc_error_loc := 'Waiting for the GL Transfer program to complete';
          lb_req_status := FND_CONCURRENT.WAIT_FOR_REQUEST(
                                                           request_id   => ln_gl_trf_req_id
                                                           ,interval    => ln_max_wait_int
                                                           ,max_wait    => ln_max_wait_time
                                                           ,phase       => lc_phase
                                                           ,status      => lc_status
                                                           ,dev_phase   => lc_devphase
                                                           ,dev_status  => lc_devstatus
                                                           ,message     => lc_message
                                                          );
          IF (lb_req_status) THEN
             FND_FILE.PUT_LINE(FND_FILE.LOG,'Waiting for the completion of GL Transfer program');
          ELSE
             FND_FILE.PUT_LINE(FND_FILE.LOG,'Wait for request returned FALSE');
          END IF;
          
          /*lc_error_loc := 'Getting the concurrent request details';
          SELECT fcr.concurrent_program_id
                 ,fcr.program_application_id
                 ,fcr.request_id
                 ,fcr.parent_request_id
                 ,fcr.status_code
                 ,fcr.request_date
                 ,fcr.actual_start_date
                 ,fcr.actual_completion_date
          INTO   ln_conc_prog_id
                 ,ln_application_id
                 ,ln_request_id
                 ,ln_par_req_id
                 ,lc_req_state
                 ,ld_req_date
                 ,ld_act_strt_date
                 ,ld_act_comp_date
          FROM   fnd_concurrent_requests fcr
          WHERE  fcr.request_id = ln_gl_trf_req_id;

          lc_error_loc := 'Getting the GL Interface record details';
          SELECT gi.group_id
                 ,gsob.name
                 ,gi.currency_code
                 ,COUNT(gi.group_id)
                 ,NVL(SUM(entered_dr),0)
                 ,NVL(SUM(entered_cr),0)
          INTO   ln_group_id
                 ,lc_sob_name
                 ,lc_currency
                 ,ln_count
                 ,ln_total_dr
                 ,ln_total_cr
          FROM   gl_interface gi
                 ,gl_sets_of_books gsob
          WHERE  gi.user_je_source_name = gc_receivables
          AND    gi.set_of_books_id = gsob.set_of_books_id
          AND    gi.request_id = ln_gl_trf_req_id
          GROUP BY gi.group_id
                   ,gsob.name
                   ,gi.currency_code;                      

          lc_error_loc := 'Inserting the concurrent request details into XX_FIN_PROGRAM_STATS';
          INSERT INTO XX_FIN_PROGRAM_STATS(
                          program_short_name
                          ,concurrent_program_id
                          ,application_id
                          ,request_id
                          ,parent_request_id
                          ,request_submitted_time
                          ,request_start_time
                          ,request_end_time
                          ,request_status
                          ,count
                          ,total_dr
                          ,total_cr
                          ,sob
                          ,currency
                          ,attribute1
                          ,attribute2
                          ,attribute3
                          ,attribute4
                          ,attribute5
                          ,run_date
                          ,event_number
                          ,group_id
                         )
                   VALUES(
                          'ARGLTP'
                          ,ln_conc_prog_id    
                          ,ln_application_id 
                          ,ln_request_id     
                          ,ln_par_req_id     
                          ,ld_req_date     
                          ,ld_act_strt_date                
                          ,ld_act_comp_date               
                          ,lc_req_state              
                          ,ln_count                            
                          ,ln_total_dr                          
                          ,ln_total_cr              
                          ,lc_sob_name                   
                          ,lc_currency
                          ,NULL            
                          ,NULL            
                          ,NULL            
                          ,NULL            
                          ,NULL            
                          ,ld_run_date                                        
                          ,p_wave_num          
                          ,ln_group_id              
                         );

          FND_FILE.PUT_LINE(FND_FILE.LOG,'GL Interface record details for Group ID '|| ln_group_id ||' has been inserted into XX_FIN_PROGRAM_STATS table');
          FND_FILE.PUT_LINE(FND_FILE.LOG,'Count of Records           : '||ln_count);
          FND_FILE.PUT_LINE(FND_FILE.LOG,'Total Entered Debit        : '||ln_total_dr);
          FND_FILE.PUT_LINE(FND_FILE.LOG,'Total Entered Credit       : '||ln_total_cr);
          FND_FILE.PUT_LINE(FND_FILE.LOG,'Set of Books               : '||lc_sob_name);
          FND_FILE.PUT_LINE(FND_FILE.LOG,'Currency                   : '||lc_currency);*/
          
          lc_error_loc := 'Submitting the OD Receivables Multithread GL Journal Import Program';
          ln_rec_multi_req_id := FND_REQUEST.SUBMIT_REQUEST(
                                                            'XXFIN'
                                                            ,'ODARGLTNSFRNEW'
                                                            ,NULL
                                                            ,NULL
                                                            ,FALSE
                                                            ,p_batch_size              
                                                            ,ln_gl_trf_req_id
                                                            ,ln_max_wait_int
                                                            ,ln_max_wait_time
                                                            ,p_email_id
                                                           );                                                          
          COMMIT;
          
          IF (ln_rec_multi_req_id <> 0) THEN
             FND_FILE.PUT_LINE(FND_FILE.LOG,'OD Receivables Multithread General Ledger Journal Import Program has been submitted with Request ID :'||ln_rec_multi_req_id);

             --Wait till the OD Receivables Multithread General Ledger Journal Import Program has finished
             lc_error_loc := 'Waiting for the OD Receivables Multithread General Ledger Journal Import Program to complete';
             lb_req_status_mul := FND_CONCURRENT.WAIT_FOR_REQUEST(
                                                                  request_id   => ln_rec_multi_req_id
                                                                  ,interval    => ln_max_wait_int
                                                                  ,max_wait    => ln_max_wait_time
                                                                  ,phase       => lc_phase_mul
                                                                  ,status      => lc_status_mul
                                                                  ,dev_phase   => lc_devphase_mul
                                                                  ,dev_status  => lc_devstatus_mul
                                                                  ,message     => lc_message_mul
                                                                 );
             IF (lb_req_status_mul) THEN
                FND_FILE.PUT_LINE(FND_FILE.LOG,'Waiting for the completion of OD Receivables Multithread General Ledger Journal Import Program');
             ELSE
                FND_FILE.PUT_LINE(FND_FILE.LOG,'Wait for request returned FALSE');
             END IF;
          END IF;
          ln_multi_ro_mail_req_id := FND_REQUEST.SUBMIT_REQUEST(
                                                                'XXFIN'
                                                                ,'XXODROEMAILER'
                                                                ,NULL
                                                                ,NULL
                                                                ,FALSE
                                                                ,'ODARGLTNSFRNEW'              
                                                                ,p_email_id
                                                                ,'OD Receivables Multithread Program Output'
                                                                ,'Please find attached the OD Receivables Multithread Program Output'
                                                                ,'Y'
                                                                ,ln_rec_multi_req_id
                                                               );
       END IF;

       FND_FILE.PUT_LINE(FND_FILE.LOG,'End of OD: AR General Ledger Transfer Program');
       FND_FILE.PUT_LINE(FND_FILE.LOG,'**********************************************************************************************************');

    EXCEPTION
       WHEN OTHERS THEN
          lc_error_msg := 'Error occured in OD: AR General Ledger Transfer Program at '||lc_error_loc||'. The Oracle error is '||SQLERRM||' : '||SQLCODE;
          FND_FILE.PUT_LINE(FND_FILE.LOG,'**********************************************************************************************************');
          FND_FILE.PUT_LINE(FND_FILE.LOG,'Error occured in OD: AR General Ledger Transfer Program'||CHR(10)||'at '||lc_error_loc
                                          ||'. The Oracle error is '||SQLERRM||' : '||SQLCODE);
          FND_FILE.PUT_LINE(FND_FILE.LOG,'End of OD: AR General Ledger Transfer Program');
          FND_FILE.PUT_LINE(FND_FILE.LOG,'**********************************************************************************************************');
          XX_COM_ERROR_LOG_PUB.LOG_ERROR(
                                         p_program_type                => 'CONCURRENT PROGRAM'
                                         ,p_program_id                  => fnd_global.conc_program_id
                                         ,p_module_name                 => 'AR'
                                         ,p_error_location              => SUBSTR('Error at '|| lc_error_loc,1,60)
                                         ,p_error_message_count         => 1
                                         ,p_error_message_code          => 'E'
                                         ,p_error_message               => lc_error_msg
                                         ,p_error_message_severity      => 'Warning'
                                         ,p_notify_flag                 => 'N'
                                         ,p_object_type                 => lc_object_type
                                         ,p_object_id                   => ln_object_id
                                         );
          x_ret_code := 2;
    END SUBMIT_PROGRAM;

 END XX_AR_GL_TRANSFER_PKG_NEW;
 
/
SHOW ERROR