 SET SHOW OFF
 SET VERIFY OFF
 SET ECHO OFF
 SET TAB OFF
 SET FEEDBACK OFF
 SET TERM ON

 WHENEVER SQLERROR CONTINUE


create or replace
PACKAGE XX_AR_SUMMARIZE_POS_INV_PKG AS 
    -- +=====================================================================+
    -- | Name : XX_AR_SUMMARIZE_POS_INV_PKG                                  |
    -- | Description :                                                       |
    -- |             Release 11.3 AR Sales Data Redesign - AR Track          |
    -- |             Package calling program: E80 called from OD: AR Summarize 
    -- |             POS Sales                                               |
    -- | Parameters                                                          | 
    -- | Returns :                                                           |
    -- | Change Record:                                                      |
    -- |===============                                                      |
    -- |Version   Date              Author                  Remarks          |
    -- |======   ==========     =============     ===========================|
    -- |1.0      17-MAR-2011    P. Marco                                     |
    -- +=====================================================================+


    -- +=====================================================================+
    -- | Name : MAIN                                                         |
    -- | Description :                                                       |
    -- |             Release 11.3 AR Sales Data Redesign - AR Track          |
    -- |             Main calling program: E80 called from OD: AR Summarize  |
    -- |             POS Sales                                               |
    -- | Parameters                                                          |
    -- | Returns :                                                           |   
    -- +=====================================================================+
    PROCEDURE MAIN( x_err_buff             OUT VARCHAR2
                   ,x_ret_code             OUT NUMBER
                   ,p_process_date	        IN VARCHAR2
                   ,p_batch_source_name	    IN VARCHAR2 DEFAULT NULL
                   ,p_child_threads          IN  NUMBER
                   ,p_autoinv_thread_count	IN NUMBER	
                   ,p_email_address	        IN VARCHAR2	DEFAULT NULL 
                   ,p_org_id	              IN NUMBER	
                   ,p_wave_number           IN NUMBER
                   ,p_display_log_details	  IN VARCHAR2
                   ,p_bulk_limit            IN	NUMBER	
                  );


    -- +=====================================================================+
    -- | Name : SUMMARIZE_STORES                                             |
    -- | Description :                                                       |
    -- |             Procedure used to multi-thread Summarization of POS     |
    -- | Parameters                                                          |
    -- | Returns :                                                           |   
    -- +=====================================================================+

                  
                  
   PROCEDURE SUMMARIZE_STORES (x_err_buff             OUT  VARCHAR2
                              ,x_ret_code             OUT  NUMBER
                              ,p_process_date          IN  VARCHAR2
                              ,p_batch_source_name     IN  VARCHAR2
                              ,p_org_id                IN  NUMBER	
                              ,p_autoinv_thread_count  IN  NUMBER
                              ,p_email_address         IN  VARCHAR2
                              ,p_cust_id_low           IN  NUMBER
                              ,p_cust_id_high          IN  NUMBER                            
                              ,p_wave_number           IN  NUMBER
                              ,p_display_log_details   IN  VARCHAR2
                              ,p_bulk_limit            IN  NUMBER);                  

END XX_AR_SUMMARIZE_POS_INV_PKG;
/
