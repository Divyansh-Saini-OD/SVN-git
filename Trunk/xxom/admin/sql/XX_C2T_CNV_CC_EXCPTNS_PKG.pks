create or replace PACKAGE      XX_C2T_CNV_CC_EXCPTNS_PKG IS
---+============================================================================================+
---|                              Office Depot                                                  |
---+============================================================================================+
---|    Application     : OM                                                                    |
---|                                                                                            |
---|    Name            : XX_C2T_CNV_CC_EXCPTNS_PKG.pks                                      |
---|                                                                                            |
---|    Description     : Pre-Processing Credit Cards for OE Payments, Deposits, Returns, IBY   |
---|                      History and ORDT                                                      |
---|    Rice ID         : C0705                                                                 |
---|    Change Record                                                                           |
---|    --------------------------------------------------------------------------              |
---|    Version         DATE              AUTHOR             DESCRIPTION                        |
---|    ------------    ----------------- ---------------    ---------------------              |
---|    1.0             02-FEB-2016       Havish Kasina      Initial Version for Payments       |
---|                                                         Deposits and Returns               |
---+============================================================================================+
				   

                     
   PROCEDURE extract_pmts_exceptions ( 
                                        p_debug_flag               IN           VARCHAR2									
                                     );	
                                     
                     
   PROCEDURE extract_deps_exceptions ( 
                                        p_debug_flag               IN           VARCHAR2                                    
                                     );		
 
                     
   PROCEDURE extract_rets_exceptions ( 
                                       p_debug_flag               IN           VARCHAR2									
                                     );	
									 
   PROCEDURE extract_iby_hist_exceptions ( 
                                             p_debug_flag               IN           VARCHAR2									
                                         );	
									 
   PROCEDURE extract_ordt_exceptions ( 
                                       p_debug_flag               IN           VARCHAR2									
                                     );	
								 
   PROCEDURE exceptions_main        ( 
                                       x_errbuf                   OUT NOCOPY   VARCHAR2
                                      ,x_retcode                  OUT NOCOPY   NUMBER
                                      ,p_debug_flag               IN           VARCHAR2	
                                      ,p_process_type             IN           VARCHAR2	
									);
                                 
END XX_C2T_CNV_CC_EXCPTNS_PKG;
/