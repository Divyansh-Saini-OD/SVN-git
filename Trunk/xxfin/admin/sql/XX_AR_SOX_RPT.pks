CREATE OR REPLACE PACKAGE XX_AR_SOX_RPT
AS
-- +====================================================================+
-- |                  Office Depot - Project Simplify                   |
-- |                         Wipro Technology                           |
-- +====================================================================+
-- | Name         : XX_AR_SOX_RPT                                       |
-- | Description  : This package is used to get the Daily Invoices count|
-- |                and amount for all billing methods (Certegy, EDI,   |
-- |                EBill and Special Handling)                         |
-- |                                                                    |
-- |Change Record:                                                      |
-- |===============                                                     |
-- |Version  Date         Author         Remarks                        |
-- |=======  ===========  =============  ===============================|
-- | 1       03-MAR-2010  Lincy K        Initial version                |
-- |                                     Created for Defect 2348 and 1676        |
-- +====================================================================+

-- +====================================================================+
-- | Name       : XX_AR_SOX_CALC                                        |
-- | Description:                                                       |
-- |                                                                    |
-- | Parameters : p_delivery_method, p_print_date, p_requests_id        |
-- |              p_email_address and  p_sender_address                 |
-- |                                                                    |
-- | Returns :   x_errbuf, x_ret_code                                   |
-- |                                                                    |
-- |                                                                    |
-- +====================================================================+

 PROCEDURE XX_AR_SOX_CALC (x_errbuf             OUT    VARCHAR2
                          ,x_ret_code           OUT    NUMBER
                          ,p_delivery_method    IN     VARCHAR2
                          ,p_print_date         IN     VARCHAR2
                          ,p_email_address      IN     VARCHAR2
                          ,p_sender_address     IN     VARCHAR2);

PROCEDURE XX_AR_SOX_PRINT_NULL( p_country      IN VARCHAR2
                               ,p_conc_prog    IN VARCHAR2
                               ,p_inv_type     IN VARCHAR2
                               ,p_id_flg       IN NUMBER
                               ,p_pd_flg       IN NUMBER);

END XX_AR_SOX_RPT;
/
SHO ERR;