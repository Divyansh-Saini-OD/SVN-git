---+========================================================================================================+        
---|                                        Office Depot - Project Simplify                                 |
---+========================================================================================================+
---|    Application             :       AR                                                                  |
---|                                                                                                        |
---|    Name                    :       XX_AR_AUTO_INVOICE_INDEX_DROP.SQL                                   |
---|                                                                                                        |
---|    Description             :       This script drops the indexes created by the script                 |  
---|                                        XX_AR_AUTO_INVOICE_INDEXES.SQL                                  |
---|                                                                                                        |
---|                                                                                                        |
---|                                                                                                        |
---|    Change Record                                                                                       |
---|    ---------------------------------                                                                   |
---|    Version         DATE              AUTHOR            DESCRIPTION                                     |
---|    ------------    ----------------- ---------------   ---------------------                           |
---|    1.0             14-APR-2008       Raghu              Initial Version                                |
---|                                                                                                        |
---+========================================================================================================+        


DROP INDEX XXFIN.XX_AR_CUSTOMER_TRX_N1;
DROP INDEX XXFIN.XX_AR_CUSTOMER_TRX_N2;
DROP INDEX XXFIN.XX_AR_CUSTOMER_TRX_N3;
DROP INDEX XXFIN.XX_RA_CUSTOMER_TRX_LINES_N1;
DROP INDEX XXFIN.XX_RA_CUSTOMER_TRX_N3;
DROP INDEX XXFIN.XX_RA_CUSTOMER_TRX_N4;

DROP INDEX XXFIN.XX_RA_INTERFACE_DISTRIB_N1;
DROP INDEX XXFIN.XX_RA_INTERFACE_DISTRIB_N2;
DROP INDEX XXFIN.XX_RA_INTERFACE_DISTRIB_N3;
DROP INDEX XXFIN.XX_RA_INTERFACE_LINES_N1;
DROP INDEX XXFIN.XX_RA_INTERFACE_LINES_N2;
DROP INDEX XXFIN.XX_RA_INTERFACE_SCREDIT_N1;
DROP INDEX XXFIN.XX_RA_INTERFACE_SCREDIT_N2;