CREATE OR REPLACE PACKAGE APPS.XX_AR_CREDIT_CHECK_WRAPPER_PKG AS
---+========================================================================================================+
---|                                        Office Depot - Project Simplify                                 |
---|                             Oracle NAIO/WIPRO/Office Depot/Consulting Organization                     |
---+========================================================================================================+
---|    Application             :       AR                                                                  |
---|                                                                                                        |
---|    Name                    :       xx_ar_credit_check_wrapper_pkg                                      |
---|                                                                                                        |
---|    Description             :                                                                           |
---|                                                                                                        |
---|                                                                                                        |
---|                                                                                                        |
---|    Change Record                                                                                       |
---|    ---------------------------------                                                                   |
---|    Version         DATE              AUTHOR            DESCRIPTION                                     |
---|    ------------    ----------------- ---------------   ---------------------                           |
---|    1.0             26-JUL-2012       Ray Strauss       Initial Version                                 |

---+========================================================================================================+

PROCEDURE CREDIT_CHECK_WRAPPER (errbuf          OUT NOCOPY VARCHAR2,
                                retcode         OUT NOCOPY NUMBER,
                                p_store_num     IN  VARCHAR2,
                                p_register_num  IN  VARCHAR2,
                                p_sale_tran     IN  VARCHAR2,
                                p_order_num     IN  VARCHAR2,
                                p_sub_order_num IN  VARCHAR2,
                                p_account_num   IN  VARCHAR2,
                                p_amt           IN  NUMBER,
                                p_updt_flag     IN  VARCHAR2) ;

END XX_AR_CREDIT_CHECK_WRAPPER_PKG ;
/
