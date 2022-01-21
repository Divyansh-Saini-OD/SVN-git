create or replace
PACKAGE XX_XX_POS_TEST_PKG AS 
    PROCEDURE MAIN (x_err_buff              OUT  VARCHAR2
                   ,x_ret_code              OUT  NUMBER
                   ,p_process_date	         IN  VARCHAR2
                   ,p_batch_source_name	   IN  VARCHAR2  DEFAULT NULL
                   ,p_autoinv_thread_count   IN  NUMBER	
                   ,p_email_address	         IN  VARCHAR2  DEFAULT NULL 
                   ,p_org_id	               IN  NUMBER	
                   ,p_wave_number            IN  NUMBER
                   ,p_display_log_details	   IN  VARCHAR2
                   ,p_bulk_limit             IN	 NUMBER
                   ,p_child_threads          IN  NUMBER);  

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

END XX_XX_POS_TEST_PKG;

/