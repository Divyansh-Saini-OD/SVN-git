CREATE OR REPLACE PACKAGE APPS.XX_AR_CREDIT_CHECK_PKG AS
---+========================================================================================================+
---|                                        Office Depot - Project Simplify                                 |
---|                             Oracle NAIO/WIPRO/Office Depot/Consulting Organization                     |
---+========================================================================================================+
---|    Application             :       AR                                                                  |
---|                                                                                                        |
---|    Name                    :       xx_ar_credit_check.pls                                              |
---|                                                                                                        |
---|    Description             :                                                                           |
---|                                                                                                        |
---|                                                                                                        |
---|                                                                                                        |
---|    Change Record                                                                                       |
---|    ---------------------------------                                                                   |
---|    Version         DATE              AUTHOR            DESCRIPTION                                     |
---|    ------------    ----------------- ---------------   ---------------------                           |
---|    1.0             14-FEB-2007       Shiva Rao         Initial Version                                 |
---|    1.1             15-NOV-2007       Cecilia Macean    Added GET_VK_CREDIT_STATUS                      |
---|                                                                                                        |
-- |    1.2             26-NOV-2008       P.Suresh          Defect 11910 - Introduced EXTRACT_DIRECT_VIKING |
-- |                                                        DETAILS and EXTRACT_CONTR_BACKUP_DETAILS.       |
---+========================================================================================================+


PROCEDURE EXTRACT_CREDIT_DETAILS(errbuf       OUT NOCOPY VARCHAR2,
                                 retcode      OUT NOCOPY NUMBER,
                                 p_as_of_date VARCHAR2) ;


PROCEDURE EXTRACT_CONTR_BACKUP_DETAILS(errbuf       OUT NOCOPY VARCHAR2,
                                       retcode      OUT NOCOPY NUMBER,
                                       p_as_of_date     VARCHAR2);


PROCEDURE CREDIT_CHECK (p_store_num     VARCHAR2,
                        p_register_num  VARCHAR2,
                        p_sale_tran     VARCHAR2,
                        p_order_num     VARCHAR2,
                        p_sub_order_num VARCHAR2,
                        p_account_num   VARCHAR2,
                        p_amt           NUMBER,
                        p_response_act  OUT NOCOPY VARCHAR2,
                        p_response_code OUT NOCOPY VARCHAR2,
                        p_response_text OUT NOCOPY VARCHAR2) ;

PROCEDURE OTB_PURGE(errbuf OUT NOCOPY VARCHAR2,
                    retcode OUT NOCOPY NUMBER);


PROCEDURE GET_VK_CREDIT_STATUS(p_account_num  IN  VARCHAR2,
                                p_buc_amt_0   OUT NUMERIC,
                                p_buc_amt_1   OUT NUMERIC,
                                p_buc_amt_2   OUT NUMERIC,
                                p_buc_amt_3   OUT NUMERIC,
                                p_buc_amt_4   OUT NUMERIC,
                                p_buc_amt_5   OUT NUMERIC,
                                p_out_bal     OUT NUMERIC,
                                p_rcpt_date       OUT DATE,
                                p_collector_id    OUT NUMERIC,
                                p_collector_name  OUT NOCOPY VARCHAR2,
                                p_response_code   OUT NOCOPY VARCHAR2,
                                p_response_message   OUT NOCOPY VARCHAR2);


END XX_AR_CREDIT_CHECK_PKG ;
/
