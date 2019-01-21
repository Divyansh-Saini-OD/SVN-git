CREATE OR REPLACE PACKAGE APPS.XX_SPC_OPEN_TRANSACTIONS_PKG  
AS
-- +======================================================================================+
-- |                        Office Depot                                                  |
-- +======================================================================================+
-- | Name  : XX_SPC_OPEN_TRANSACTIONS_PKG                                                 |
-- | Rice ID: R1395                                                                       |
-- | Description      : This program will submit the concurrent requests for two programs |
-- |                                                                                      |
-- |                                                                                      |
-- |Change Record:                                                                        |
-- |===============                                                                       |
-- |Version Date        Author            Remarks                                         |
-- |======= =========== =============== ==================================================|
-- |1.0     25-APR-2015 Havish Kasina   Initial draft version                             |
-- +======================================================================================+
     
PROCEDURE EXTRACT(
                  x_retcode              OUT NOCOPY    NUMBER,
                  x_errbuf               OUT NOCOPY    VARCHAR2,
                  p_operating_unit       IN            NUMBER,
                  p_as_of_date           IN            VARCHAR2,
                  p_no_of_days           IN            NUMBER,
                  p_order_source         IN            VARCHAR2,
                  p_smtp_server          IN            VARCHAR2,
                  p_mail_from            IN            VARCHAR2,
                  p_mail_to              IN            VARCHAR2,
                  p_mail_cc              IN            VARCHAR2
                 );
END;
/
SHOW ERRORS;

