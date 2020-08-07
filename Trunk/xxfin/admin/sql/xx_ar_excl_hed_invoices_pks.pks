CREATE OR REPLACE PACKAGE APPS.xx_ar_excl_hed_invoices_pkg IS
---+============================================================================================+        
---|                              Office Depot - Project Simplify                               |
---|                                   Providge Consulting                                      |
---+============================================================================================+
---|    Application     : AR                                                                    |
---|                                                                                            |
---|    Name            : xx_ar_excl_hed_invoices_pks.pks                                       |
---|                                                                                            |
---|    Description     : Exclude hedberg invoices from standard consolidated billing process.  |
---|                                                                                            |
---|                                                                                            |
---|                                                                                            |
---|    Change Record                                                                           |
---|    ---------------------------------                                                       |
---|    Version         DATE              AUTHOR             DESCRIPTION                        |
---|    ------------    ----------------- ---------------    ---------------------              |
---|    1.0             11-MAR-2008       Sairam Bala        Initial Version                    |
---|                                                                                            |
---+============================================================================================+ 
    -- 
    -- If Request ID parameter is not specified, then the program updates AR_PAYMENT_SCHEDULES_ALL 
    -- for all HED invoices imported by Auto Invoice Import program (as part of the request set) 
    -- When a Request ID is provided, program updates AR_PAYMENT_SCHEDULES_ALL for all HED invoices
    -- imported by Auto Invoice Import (Master or Child Programs) specified by the provided Request ID 
    -- 
    PROCEDURE main (ps_errbuf    OUT NOCOPY     VARCHAR2
                   ,pn_retcode   OUT NOCOPY     NUMBER
                   ,pn_request_id IN            NUMBER DEFAULT NULL
                   );

END xx_ar_excl_hed_invoices_pkg;
/