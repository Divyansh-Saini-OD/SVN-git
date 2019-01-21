CREATE OR REPLACE PACKAGE APPS.XX_AR_ZERO_TAX_ROWS_DELETE_PKG IS
---+============================================================================================+        
---|                              Office Depot - Project Simplify                               |
---+============================================================================================+
---|    Application     : AR                                                                    |
---|                                                                                            |
---|    Name            : XX_AR_ZERO_TAX_ROWS_DELETE_PKG.pkb                                    |
---|                                                                                            |
---|    Description     : Delete 0 tax rows from RA_CUSTOMER_TRX_LINES_ALL and                  |
---|                      RA_CUST_TRX_LINE_GL_DIST_ALL                                          |
---|                                                                                            |
---|                                                                                            |
---|    Change Record                                                                           |
---|    ---------------------------------                                                       |
---|    Version         DATE              AUTHOR             DESCRIPTION                        |
---|    ------------    ----------------- ---------------    ---------------------              |
---|    1.0             29-SEP-2009       Prakash Sankaran   Initial Version                    |
---+============================================================================================+

   
PROCEDURE main (ps_errbuf    OUT NOCOPY     VARCHAR2
                ,pn_retcode   OUT NOCOPY     NUMBER
                ,pn_request_id IN            NUMBER DEFAULT NULL
                );

        
END XX_AR_ZERO_TAX_ROWS_DELETE_PKG;
/