create or replace PACKAGE      XX_C2T_CNV_CC_TOKEN_OM_PKG IS
---+============================================================================================+
---|                              Office Depot                                                  |
---+============================================================================================+
---|    Application     : OM                                                                    |
---|                                                                                            |
---|    Name            : XX_C2T_CNV_CC_TOKEN_OM_PKG.pks                                        |
---|                                                                                            |
---|    Description     : Pre-Processing Credit Cards for OE Payments, Deposits and Returns     |
---|                                                                                            |
---|    Rice ID         : C0705                                                                 |
---|    Change Record                                                                           |
---|    --------------------------------------------------------------------------              |
---|    Version         DATE              AUTHOR             DESCRIPTION                        |
---|    ------------    ----------------- ---------------    ---------------------              |
---|    1.0             17-SEP-2015       Havish Kasina      Initial Version for Payments       |
---|                                                         and Deposits                       |
---|    1.1             28-SEP-2015       Manikant Kasu      Initial Version for Returns        |
---+============================================================================================+
				   
  -- OE Payments			   
   PROCEDURE prepare_pmts_master (   x_errbuf                   OUT NOCOPY   VARCHAR2
                                    ,x_retcode                  OUT NOCOPY   NUMBER
                                    ,p_child_threads            IN           NUMBER      
                                    ,p_processing_type          IN           VARCHAR2
                                    ,p_recreate_child_thrds     IN           VARCHAR2  
                                    ,p_batch_size               IN           NUMBER 
                                    ,p_debug_flag               IN           VARCHAR2									
                                 );
                     
   PROCEDURE prepare_pmts_child (    x_errbuf                   OUT NOCOPY   VARCHAR2
                                    ,x_retcode                  OUT NOCOPY   NUMBER
                                    ,p_child_threads            IN           NUMBER
                                    ,p_child_thread_num         IN           NUMBER
                                    ,p_processing_type          IN           VARCHAR2      
                                    ,p_min_oe_payment_id        IN           NUMBER
                                    ,p_max_oe_payment_id        IN           NUMBER
                                    ,p_batch_size               IN           NUMBER 
                                    ,p_debug_flag               IN           VARCHAR2									
                                 );	
                                 
  -- Deposits			   
   PROCEDURE prepare_deps_master (   x_errbuf                   OUT NOCOPY   VARCHAR2
                                    ,x_retcode                  OUT NOCOPY   NUMBER
                                    ,p_child_threads            IN           NUMBER      
                                    ,p_processing_type          IN           VARCHAR2
                                    ,p_recreate_child_thrds     IN           VARCHAR2  
                                    ,p_batch_size               IN           NUMBER  
                                    ,p_debug_flag               IN           VARCHAR2									
                                 );
                     
   PROCEDURE prepare_deps_child (    x_errbuf                   OUT NOCOPY   VARCHAR2
                                    ,x_retcode                  OUT NOCOPY   NUMBER
                                    ,p_child_threads            IN           NUMBER
                                    ,p_child_thread_num         IN           NUMBER
                                    ,p_processing_type          IN           VARCHAR2      
                                    ,p_min_deposit_id           IN           NUMBER
                                    ,p_max_deposit_id           IN           NUMBER
                                    ,p_batch_size               IN           NUMBER
                                    ,p_debug_flag               IN           VARCHAR2                                    
                                 );		
   -- Returns			   
   PROCEDURE prepare_rets_master (   x_errbuf                   OUT NOCOPY   VARCHAR2
                                    ,x_retcode                  OUT NOCOPY   NUMBER
                                    ,p_child_threads            IN           NUMBER      
                                    ,p_processing_type          IN           VARCHAR2
                                    ,p_recreate_child_thrds     IN           VARCHAR2  
                                    ,p_batch_size               IN           NUMBER  
                                    ,p_debug_flag               IN           VARCHAR2									
                                 );
                     
   PROCEDURE prepare_rets_child (    x_errbuf                   OUT NOCOPY   VARCHAR2
                                    ,x_retcode                  OUT NOCOPY   NUMBER
                                    ,p_child_threads            IN           NUMBER
                                    ,p_child_thread_num         IN           NUMBER
                                    ,p_processing_type          IN           VARCHAR2      
                                    ,p_min_return_id            IN           NUMBER
                                    ,p_max_return_id            IN           NUMBER
                                    ,p_batch_size               IN           NUMBER    
                                    ,p_debug_flag               IN           VARCHAR2									
                                 );	
                                 
END XX_C2T_CNV_CC_TOKEN_OM_PKG;
/